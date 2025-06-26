#ifndef CONSOLE_H
#define CONSOLE_H

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
    char *input;
    bool is_valid;
} ConsoleArgs;

static ConsoleArgs console_args_parse(int argc, char **argv, char **envp) {
    ConsoleArgs args = {NULL, false};
    if (argc > 1) {
        args.input = strdup(argv[1]);
        args.is_valid = true;
    }
    return args;
}

static void console_args_free(ConsoleArgs args) {
    if (args.input) {
        free(args.input);
    }
}

int console_command_run(int argc, char **argv, char **envp) {
    ConsoleArgs args = console_args_parse(argc, argv, envp);
    if (!args.is_valid) {
        fprintf(stderr, "Invalid command line arguments\n");
        return 1;
    }
    printf("Running console: %s\n", args.input);
    console_args_free(args);
    return 0;
}

#endif // CONSOLE_H
