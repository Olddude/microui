
#ifndef CLIENT_H
#define CLIENT_H

#include "core.h"

// Enhanced client functions using execution context
int client_run(int argc, char **argv, char **envp, callback_t success, callback_t failure);
void client_execute_async(execution_context_t *ctx, int argc, char **argv, char **envp);

// Legacy compatibility
typedef int (*legacy_callback)(int argc, char **argv, char **envp);
int client_run_legacy(
    int argc,
    char **argv,
    char **envp,
    legacy_callback success,
    legacy_callback failure
);

#endif
