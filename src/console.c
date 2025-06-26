#include "console.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
    char *input;
    bool is_valid;
} console_args_t;

static console_args_t console_args_parse(int argc, char **argv, char **envp) {
    console_args_t args = {NULL, false};
    if (argc > 1) {
        args.input = strdup(argv[1]);
        args.is_valid = true;
    }
    return args;
}

static void console_args_free(console_args_t args) {
    if (args.input) {
        free(args.input);
    }
}

int console_command_run(int argc, char **argv, char **envp) {
    console_args_t args = console_args_parse(argc, argv, envp);
    if (!args.is_valid) {
        fprintf(stderr, "Invalid command line arguments\n");
        return 1;
    }
    printf("Running console: %s\n", args.input);
    console_args_free(args);
    return 0;
}
