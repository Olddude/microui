#include "core.h"
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Thread data structure for parallel execution
typedef struct
{
    callback_t callback;
    int argc;
    char **argv;
    char **envp;
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
    execution_context_t *ctx = malloc(sizeof(execution_context_t));
    if (!ctx)
        return NULL;

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
callback_chain_t *create_chain(callback_t callback) {
    callback_chain_t *chain = malloc(sizeof(callback_chain_t));
    if (!chain)
        return NULL;

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

    // Clean up callback chain
    callback_chain_t *current = ctx->chain;
    while (current) {
        callback_chain_t *next = current->next;
        if (current->data)
            free(current->data);
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
    if (!ctx || !other || !other->chain)
        return;

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
    if (!ctx || ctx->completed)
        return;

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
            ctx->on_error(0, NULL, NULL);
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
    if (!ctx->chain)
        return;

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
        thread_data[i].argc = ctx->argc;
        thread_data[i].argv = ctx->argv;
        thread_data[i].envp = ctx->envp;
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
        data->callback(data->argc, data->argv, data->envp, data->ctx);

        pthread_mutex_lock(data->mutex);
        *(data->result) = RESULT_SUCCESS;
        (*data->active_count)--;

        if (data->ctx->on_next) {
            data->ctx->on_next(data->argc, data->argv, data->envp);
        }
        pthread_mutex_unlock(data->mutex);
    }

    return NULL;
}
