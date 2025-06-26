#include "client.h"
#include "core.h"
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

// Create a client-specific execution context
static execution_context_t *client_create_context(execution_strategy_t strategy) {
    execution_context_t *ctx = create_context(strategy);
    if (!ctx) {
        return NULL;
    }

    // Client-specific configuration could go here
    return ctx;
}

// Add middleware to client context
static void client_add_middleware(execution_context_t *ctx, callback_t middleware) {
    if (ctx && middleware) {
        ctx->subscribe(ctx, middleware);
    }
}

// Enhanced client run with execution context
int client_run(int argc, char **argv, char **envp) {
    execution_context_t *ctx = client_create_context(EXEC_SEQUENTIAL);
    if (!ctx) {
        return 1;
    }

    // Add default middleware
    client_add_middleware(ctx, client_init_callback);
    client_add_middleware(ctx, client_connect_callback);
    client_add_middleware(ctx, client_process_callback);

    // Execute the chain
    set_context_args(ctx, argc, argv, envp);
    ctx->execute(ctx);

    int result = ctx->completed ? 0 : 1;
    destroy_context(ctx);
    return result;
}
