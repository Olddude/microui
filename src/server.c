#include "server.h"
#include "console.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Example server handler callbacks
static void server_init_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Server: Initializing...\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

static void server_bind_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Server: Binding to port...\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

static void server_listen_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Server: Listening for connections...\n");

    // Main server loop - keep running until context is completed (e.g., by signal)
    int connection_count = 0;
    while (!ctx->completed) {
        printf("Server: Waiting for client connections... (iteration %d)\n", ++connection_count);

        // Try to run console operations, but don't fail if they don't work
        int console_result = console_run(argc, argv, envp);
        if (console_result == 0) {
            printf("Server: Console operation successful\n");
        }
        else {
            printf("Server: Console operation returned %d (continuing anyway)\n", console_result);
        }

        // Simulate handling a connection
        printf("Server: Processing simulated client request #%d\n", connection_count);

        // Small delay to prevent busy waiting and allow signal handling
        usleep(500000); // 500ms

        // Limit iterations for demo purposes
        if (connection_count >= 10) {
            printf("Server: Reached maximum iterations, stopping...\n");
            break;
        }
    }

    printf("Server: Stopped listening after %d connections\n", connection_count);
}

static void
server_handle_request_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Server: Handling client request...\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

// Create a server-specific execution context
static execution_context_t *server_create_context(execution_strategy_t strategy) {
    execution_context_t *ctx = create_context(strategy);
    if (!ctx)
        return NULL;

    // Server-specific configuration
    // Default to parallel execution for handling multiple connections
    if (strategy == EXEC_SEQUENTIAL) {
        ctx->switch_strategy(ctx, EXEC_PARALLEL);
    }

    return ctx;
}

// Add handler to server context
static void server_add_handler(execution_context_t *ctx, callback_t handler) {
    if (ctx && handler) {
        ctx->subscribe(ctx, handler);
    }
}

// Enhanced server run with execution context
int server_run(int argc, char **argv, char **envp, callback_t success, callback_t failure) {
    execution_context_t *ctx = server_create_context(EXEC_PARALLEL);
    if (!ctx)
        return -1;

    // Add server handlers in parallel execution
    server_add_handler(ctx, server_init_callback);
    server_add_handler(ctx, server_bind_callback);
    server_add_handler(ctx, server_listen_callback);
    server_add_handler(ctx, server_handle_request_callback);

    // Add user callbacks
    if (success)
        server_add_handler(ctx, success);

    // Set up lifecycle handlers
    ctx->on_complete = (lifecycle_callback_t) success;
    ctx->on_error = (lifecycle_callback_t) failure;

    // Execute the handlers
    set_context_args(ctx, argc, argv, envp);
    ctx->execute(ctx);

    int result = ctx->completed ? 0 : -1;
    destroy_context(ctx);
    return result;
}

// Execute server context with parallel handlers
void server_execute_parallel(execution_context_t *ctx, int argc, char **argv, char **envp) {
    if (!ctx)
        return;

    // Ensure parallel execution for server operations
    ctx->switch_strategy(ctx, EXEC_PARALLEL);
    set_context_args(ctx, argc, argv, envp);
    ctx->execute(ctx);
}

// Legacy compatibility function
int server_run_legacy(
    int argc,
    char **argv,
    char **envp,
    legacy_callback success,
    legacy_callback failure
) {
    if (console_run(argc, argv, envp) == 0) {
        return success ? success(argc, argv, envp) : 0;
    }
    return failure ? failure(argc, argv, envp) : -1;
}
