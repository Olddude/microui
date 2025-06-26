#include "core.h"
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static void test_callback_1(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Callback 1 starting (thread: %lu)\n", (unsigned long) pthread_self());
    sleep(1);
    printf("Callback 1 finished\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

static void test_callback_2(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Callback 2 starting (thread: %lu)\n", (unsigned long) pthread_self());
    sleep(1);
    printf("Callback 2 finished\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

static void test_callback_3(int argc, char **argv, char **envp, execution_context_t *ctx) {
    printf("Callback 3 starting (thread: %lu)\n", (unsigned long) pthread_self());
    sleep(1);
    printf("Callback 3 finished\n");
    (void) argc;
    (void) argv;
    (void) envp;
    (void) ctx;
}

void on_complete(int argc, char **argv, char **envp) {
    printf("✅ All callbacks completed!\n");
    (void) argc;
    (void) argv;
    (void) envp;
}

int main(int argc, char **argv, char **envp) {
    printf("=== Testing Sequential Execution ===\n");
    execution_context_t *seq_ctx = create_context_with_args(EXEC_SEQUENTIAL, 0, NULL, NULL);
    seq_ctx->subscribe(seq_ctx, test_callback_1);
    seq_ctx->subscribe(seq_ctx, test_callback_2);
    seq_ctx->subscribe(seq_ctx, test_callback_3);
    seq_ctx->on_complete = on_complete;
    seq_ctx->execute(seq_ctx); // Simplified - no need to pass args!
    destroy_context(seq_ctx);

    printf("\n=== Testing Parallel Execution ===\n");
    execution_context_t *par_ctx = create_context_with_args(EXEC_PARALLEL, 0, NULL, NULL);
    par_ctx->subscribe(par_ctx, test_callback_1);
    par_ctx->subscribe(par_ctx, test_callback_2);
    par_ctx->subscribe(par_ctx, test_callback_3);
    par_ctx->on_complete = on_complete;
    par_ctx->execute(par_ctx); // Simplified - no need to pass args!
    destroy_context(par_ctx);

    return 0;
}
