#include "server.h"
#include "console.h"

#include <stdio.h>
#include <stdlib.h>

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
    if (console_run(argc, argv, envp) != 0) {
        printf("Server: Console operation failed\n");
    }
    (void) ctx;
}

static void
server_handle_request_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Server: Handling client request...\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
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

// Create a server-specific execution context
execution_context_t *server_create_context(execution_strategy_t strategy) {
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
void server_add_handler(execution_context_t *ctx, callback_t handler) {
    if (ctx && handler) {
        ctx->subscribe(ctx, handler);
    }
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
