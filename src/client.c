#include "client.h"
#include "window.h"

#include <stdio.h>
#include <stdlib.h>

// Example client middleware callbacks
static void client_init_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Client: Initializing...\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

static void client_connect_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Client: Connecting to server...\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

static void client_process_callback(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Client: Processing request...\n");
    if (window_run(argc, argv, envp) != 0) {
        printf("Client: Window operation failed\n");
    }
    (void) ctx;
}

// Enhanced client run with execution context
int client_run(int argc, char **argv, char **envp, callback_t success, callback_t failure) {
    execution_context_t *ctx = client_create_context(EXEC_SEQUENTIAL);
    if (!ctx)
        return -1;

    // Add default middleware
    client_add_middleware(ctx, client_init_callback);
    client_add_middleware(ctx, client_connect_callback);
    client_add_middleware(ctx, client_process_callback);

    // Add user callbacks
    if (success)
        client_add_middleware(ctx, success);

    // Set up lifecycle handlers
    ctx->on_complete = (lifecycle_callback_t) success;
    ctx->on_error = (lifecycle_callback_t) failure;

    // Execute the chain
    set_context_args(ctx, argc, argv, envp);
    ctx->execute(ctx);

    int result = ctx->completed ? 0 : -1;
    destroy_context(ctx);
    return result;
}

// Create a client-specific execution context
static execution_context_t *client_create_context(execution_strategy_t strategy) {
    execution_context_t *ctx = create_context(strategy);
    if (!ctx)
        return NULL;

    // Client-specific configuration could go here
    return ctx;
}

// Add middleware to client context
static void client_add_middleware(execution_context_t *ctx, callback_t middleware) {
    if (ctx && middleware) {
        ctx->subscribe(ctx, middleware);
    }
}

// Execute client context asynchronously
void client_execute_async(execution_context_t *ctx, int argc, char **argv, char **envp) {
    if (!ctx)
        return;

    // Switch to parallel execution for async
    ctx->switch_strategy(ctx, EXEC_PARALLEL);
    set_context_args(ctx, argc, argv, envp);
    ctx->execute(ctx);
}

// Legacy compatibility function
int client_run_legacy(
    int argc,
    char **argv,
    char **envp,
    legacy_callback success,
    legacy_callback failure
) {
    if (window_run(argc, argv, envp) == 0) {
        return success ? success(argc, argv, envp) : 0;
    }
    return failure ? failure(argc, argv, envp) : -1;
}
