#ifndef CORE_H
#define CORE_H

#include <pthread.h>
#include <stdbool.h>

// Forward declarations
typedef struct callback_chain callback_chain_t;
typedef struct execution_context execution_context_t;

// Execution strategies
typedef enum
{
    EXEC_SEQUENTIAL, // Execute callbacks one after another
    EXEC_PARALLEL,   // Execute callbacks concurrently
    EXEC_RACE,       // Execute in parallel, stop on first completion
    EXEC_MERGE       // Execute in parallel, merge results
} execution_strategy_t;

// Callback result status
typedef enum
{
    RESULT_SUCCESS,
    RESULT_ERROR,
    RESULT_PENDING
} callback_result_t;

// Standard callback signature for lifecycle events
typedef void (*lifecycle_callback_t)(int argc, char **argv, char **envp);

// Enhanced callback with execution context
typedef void (*callback_t)(int argc, char **argv, char **envp, execution_context_t *ctx);

// Callback chain node
struct callback_chain
{
    callback_t callback;
    callback_chain_t *next;
    callback_result_t result;
    void *data; // Optional user data
};

// Execution context with RxJS-like operators
struct execution_context
{
    execution_strategy_t strategy;
    callback_chain_t *chain;
    int active_count;
    bool completed;

    // Command line arguments stored in context
    int argc;
    char **argv;
    char **envp;

    // Lifecycle handlers
    lifecycle_callback_t on_next;
    lifecycle_callback_t on_error;
    lifecycle_callback_t on_complete;

    // Chain manipulation functions
    void (*subscribe)(execution_context_t *ctx, callback_t cb);
    void (*map)(execution_context_t *ctx, callback_t transform);
    void (*filter)(execution_context_t *ctx, bool (*predicate)(int argc, char **argv, char **envp));
    void (*merge_with)(execution_context_t *ctx, execution_context_t *other);
    void (*switch_strategy)(execution_context_t *ctx, execution_strategy_t strategy);

    // Execution control (simplified - no need to pass argc/argv/envp)
    void (*execute)(execution_context_t *ctx);
    void (*abort)(execution_context_t *ctx);
};

// Factory functions
execution_context_t *create_context(execution_strategy_t strategy);
execution_context_t *
create_context_with_args(execution_strategy_t strategy, int argc, char **argv, char **envp);
void set_context_args(execution_context_t *ctx, int argc, char **argv, char **envp);
callback_chain_t *create_chain(callback_t callback);
void destroy_context(execution_context_t *ctx);

#endif // CORE_H
