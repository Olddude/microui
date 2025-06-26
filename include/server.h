
#ifndef SERVER_H
#define SERVER_H

#include "core.h"

// Enhanced server functions using execution context
int server_run(int argc, char **argv, char **envp, callback_t success, callback_t failure);
execution_context_t *server_create_context(execution_strategy_t strategy);
void server_add_handler(execution_context_t *ctx, callback_t handler);
void server_execute_parallel(execution_context_t *ctx, int argc, char **argv, char **envp);

// Legacy compatibility
typedef int (*legacy_callback)(int argc, char **argv, char **envp);
int server_run_legacy(
    int argc,
    char **argv,
    char **envp,
    legacy_callback success,
    legacy_callback failure
);

#endif
