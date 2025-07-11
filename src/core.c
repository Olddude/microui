#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "core.h"
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Global context registry for signal handling
static execution_context_t **active_contexts = NULL;
static int active_context_count = 0;
static int active_context_capacity = 0;
static pthread_mutex_t context_registry_mutex = PTHREAD_MUTEX_INITIALIZER;
static bool signal_handlers_installed = false;

// Thread data structure for parallel execution
typedef struct
{
    callback_t callback;
    execution_context_t *ctx;
    callback_result_t *result;
    pthread_mutex_t *mutex;
    int *active_count;
} thread_data_t;

// Internal function declarations
static void execute_sequential(execution_context_t *ctx);
static void execute_parallel(execution_context_t *ctx);
static void execute_race(execution_context_t *ctx);
static void execute_merge(execution_context_t *ctx);
static void *thread_callback_wrapper(void *arg);

// Signal handling functions
static void signal_handler(int sig);
static void install_signal_handlers(void);
static void register_context(execution_context_t *ctx);
static void unregister_context(const execution_context_t *ctx);
static void cleanup_all_contexts(void);

// Forward declarations for context methods
static void ctx_subscribe(execution_context_t *ctx, callback_t cb);
static void ctx_map(execution_context_t *ctx, callback_t transform);
static void
ctx_filter(execution_context_t *ctx, bool (*predicate)(int argc, char **argv, char **envp));
static void ctx_merge_with(execution_context_t *ctx, execution_context_t *other);
static void ctx_switch_strategy(execution_context_t *ctx, execution_strategy_t strategy);
static void ctx_execute(execution_context_t *ctx);
static void ctx_abort(execution_context_t *ctx);

// Factory function to create execution context with arguments
execution_context_t *
create_context_with_args(execution_strategy_t strategy, int argc, char **argv, char **envp) {
    // Install signal handlers if not already done
    if (!signal_handlers_installed) {
        install_signal_handlers();
    }

    execution_context_t *ctx = malloc(sizeof(execution_context_t));
    if (!ctx) {
        return NULL;
    }

    memset(ctx, 0, sizeof(execution_context_t));
    ctx->strategy = strategy;
    ctx->active_count = 0;
    ctx->completed = false;

    // Store command line arguments
    ctx->argc = argc;
    ctx->argv = argv;
    ctx->envp = envp;

    // Initialize function pointers
    ctx->subscribe = ctx_subscribe;
    ctx->map = ctx_map;
    ctx->filter = ctx_filter;
    ctx->merge_with = ctx_merge_with;
    ctx->switch_strategy = ctx_switch_strategy;
    ctx->execute = ctx_execute;
    ctx->abort = ctx_abort;

    // Register context for signal handling
    register_context(ctx);

    return ctx;
}

// Factory function to create execution context
execution_context_t *create_context(execution_strategy_t strategy) {
    return create_context_with_args(strategy, 0, NULL, NULL);
}

// Helper function to set arguments on existing context
void set_context_args(execution_context_t *ctx, int argc, char **argv, char **envp) {
    if (ctx) {
        ctx->argc = argc;
        ctx->argv = argv;
        ctx->envp = envp;
    }
}

// Factory function to create callback chain node
static callback_chain_t *create_chain(callback_t callback) {
    callback_chain_t *chain = malloc(sizeof(callback_chain_t));
    if (!chain) {
        return NULL;
    }

    chain->callback = callback;
    chain->next = NULL;
    chain->result = RESULT_PENDING;
    chain->data = NULL;

    return chain;
}

// Cleanup function
void destroy_context(execution_context_t *ctx) {
    if (!ctx)
        return;

    // Unregister context from signal handling
    unregister_context(ctx);

    // Clean up callback chain
    callback_chain_t *current = ctx->chain;
    while (current) {
        callback_chain_t *next = current->next;
        if (current->data) {
            free(current->data);
        }
        free(current);
        current = next;
    }

    free(ctx);
}

// Context method implementations
static void ctx_subscribe(execution_context_t *ctx, callback_t cb) {
    if (!ctx || !cb)
        return;

    callback_chain_t *new_node = create_chain(cb);
    if (!new_node)
        return;

    // Add to end of chain
    if (!ctx->chain) {
        ctx->chain = new_node;
    }
    else {
        callback_chain_t *current = ctx->chain;
        while (current->next) {
            current = current->next;
        }
        current->next = new_node;
    }
}

static void ctx_map(execution_context_t *ctx, callback_t transform) {
    // For now, just add the transform as another callback
    // In a full implementation, this would wrap the transform logic
    ctx_subscribe(ctx, transform);
}

static void
ctx_filter(execution_context_t *ctx, bool (*predicate)(int argc, char **argv, char **envp)) {
    // Filter implementation would wrap existing callbacks with predicate check
    // For simplicity, storing predicate reference (full implementation would be more complex)
    (void) ctx;
    (void) predicate;
}

static void ctx_merge_with(execution_context_t *ctx, execution_context_t *other) {
    if (!ctx || !other || !other->chain) {
        return;
    }

    // Merge the other context's chain into this one
    if (!ctx->chain) {
        ctx->chain = other->chain;
    }
    else {
        callback_chain_t *current = ctx->chain;
        while (current->next) {
            current = current->next;
        }
        current->next = other->chain;
    }

    // Clear other's chain to avoid double-free
    other->chain = NULL;
}

static void ctx_switch_strategy(execution_context_t *ctx, execution_strategy_t strategy) {
    if (ctx) {
        ctx->strategy = strategy;
    }
}

static void ctx_execute(execution_context_t *ctx) {
    if (!ctx || ctx->completed) {
        return;
    }

    switch (ctx->strategy) {
    case EXEC_SEQUENTIAL:
        execute_sequential(ctx);
        break;
    case EXEC_PARALLEL:
        execute_parallel(ctx);
        break;
    case EXEC_RACE:
        execute_race(ctx);
        break;
    case EXEC_MERGE:
        execute_merge(ctx);
        break;
    }
}

static void ctx_abort(execution_context_t *ctx) {
    if (ctx) {
        ctx->completed = true;
        if (ctx->on_error) {
            ctx->on_error(ctx->argc, ctx->argv, ctx->envp);
        }
    }
}

// Execution strategy implementations
static void execute_sequential(execution_context_t *ctx) {
    callback_chain_t *current = ctx->chain;

    while (current && !ctx->completed) {
        if (current->callback) {
            current->callback(ctx->argc, ctx->argv, ctx->envp, ctx);
            current->result = RESULT_SUCCESS;

            if (ctx->on_next) {
                ctx->on_next(ctx->argc, ctx->argv, ctx->envp);
            }
        }
        current = current->next;
    }

    ctx->completed = true;
    if (ctx->on_complete) {
        ctx->on_complete(ctx->argc, ctx->argv, ctx->envp);
    }
}

static void execute_parallel(execution_context_t *ctx) {
    if (!ctx->chain) {
        return;
    }

    // Count callbacks
    int callback_count = 0;
    callback_chain_t *current = ctx->chain;
    while (current) {
        callback_count++;
        current = current->next;
    }

    pthread_t *threads = malloc(callback_count * sizeof(pthread_t));
    thread_data_t *thread_data = malloc(callback_count * sizeof(thread_data_t));
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

    if (!threads || !thread_data) {
        free(threads);
        free(thread_data);
        return;
    }

    ctx->active_count = callback_count;
    current = ctx->chain;

    // Launch threads
    for (int i = 0; i < callback_count && current; i++) {
        thread_data[i].callback = current->callback;
        thread_data[i].ctx = ctx;
        thread_data[i].result = &current->result;
        thread_data[i].mutex = &mutex;
        thread_data[i].active_count = &ctx->active_count;

        pthread_create(&threads[i], NULL, thread_callback_wrapper, &thread_data[i]);
        current = current->next;
    }

    // Wait for all threads
    for (int i = 0; i < callback_count; i++) {
        pthread_join(threads[i], NULL);
    }

    ctx->completed = true;
    if (ctx->on_complete) {
        ctx->on_complete(ctx->argc, ctx->argv, ctx->envp);
    }

    pthread_mutex_destroy(&mutex);
    free(threads);
    free(thread_data);
}

static void execute_race(execution_context_t *ctx) {
    // Similar to parallel but stops on first completion
    execute_parallel(ctx); // Simplified for now
}

static void execute_merge(execution_context_t *ctx) {
    // Similar to parallel but merges results
    execute_parallel(ctx); // Simplified for now
}

// Thread wrapper function
static void *thread_callback_wrapper(void *arg) {
    thread_data_t *data = (thread_data_t *) arg;

    if (data->callback) {
        data->callback(data->ctx->argc, data->ctx->argv, data->ctx->envp, data->ctx);

        pthread_mutex_lock(data->mutex);
        *(data->result) = RESULT_SUCCESS;
        (*data->active_count)--;

        if (data->ctx->on_next) {
            data->ctx->on_next(data->ctx->argc, data->ctx->argv, data->ctx->envp);
        }
        pthread_mutex_unlock(data->mutex);
    }

    return NULL;
}

// Signal handling implementation
static void signal_handler(int sig) {
    // Use write() for async-signal-safe output
    const char msg[] = "\n🛑 Received signal, cleaning up execution contexts...\n";
    write(STDERR_FILENO, msg, sizeof(msg) - 1);

    cleanup_all_contexts();

    // Restore default signal handler and re-raise
    signal(sig, SIG_DFL);
    raise(sig);
}

static void install_signal_handlers(void) {
    if (signal_handlers_installed) {
        return;
    }

    struct sigaction sa;
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;

    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);

    signal_handlers_installed = true;
}

static void register_context(execution_context_t *ctx) {
    if (!ctx) {
        return;
    }

    pthread_mutex_lock(&context_registry_mutex);

    // Expand capacity if needed
    if (active_context_count >= active_context_capacity) {
        int new_capacity = active_context_capacity == 0 ? 4 : active_context_capacity * 2;
        execution_context_t **new_contexts =
            realloc(active_contexts, new_capacity * sizeof(execution_context_t *));
        if (new_contexts) {
            active_contexts = new_contexts;
            active_context_capacity = new_capacity;
        }
        else {
            pthread_mutex_unlock(&context_registry_mutex);
            return;
        }
    }

    active_contexts[active_context_count++] = ctx;
    pthread_mutex_unlock(&context_registry_mutex);
}

static void unregister_context(const execution_context_t *ctx) {
    if (!ctx) {
        return;
    }

    pthread_mutex_lock(&context_registry_mutex);

    for (int i = 0; i < active_context_count; i++) {
        if (active_contexts[i] == ctx) {
            // Shift remaining contexts down
            for (int j = i; j < active_context_count - 1; j++) {
                active_contexts[j] = active_contexts[j + 1];
            }
            active_context_count--;
            break;
        }
    }

    pthread_mutex_unlock(&context_registry_mutex);
}

static void cleanup_all_contexts(void) {
    pthread_mutex_lock(&context_registry_mutex);

    for (int i = 0; i < active_context_count; i++) {
        execution_context_t *ctx = active_contexts[i];
        if (ctx && !ctx->completed) {
            ctx->completed = true;

            // Call error handler if available
            if (ctx->on_error) {
                ctx->on_error(ctx->argc, ctx->argv, ctx->envp);
            }
        }
    }

    // Clear the registry
    active_context_count = 0;
    free(active_contexts);
    active_contexts = NULL;
    active_context_capacity = 0;

    pthread_mutex_unlock(&context_registry_mutex);
}
