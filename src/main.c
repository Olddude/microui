#include "client.h"
#include "server.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CLIENT_COMMAND "client"
#define SERVER_COMMAND "server"
#define HELP_COMMAND "help"

void print_help(const char *program_name) {
    printf("Usage: %s <command>\n\n", program_name);
    printf("Commands:\n");
    printf("  %s    Run the client\n", CLIENT_COMMAND);
    printf("  %s    Run the server\n", SERVER_COMMAND);
    printf("  %s      Show this help message\n", HELP_COMMAND);
    printf("\nExamples:\n");
    printf("  %s %s\n", program_name, CLIENT_COMMAND);
    printf("  %s %s\n", program_name, SERVER_COMMAND);
    printf("  %s %s\n", program_name, HELP_COMMAND);
}

int main(int argc, char **argv, char **envp) {
    if (argc < 2) {
        fprintf(
            stderr,
            "Usage: %s %s|%s|%s\n",
            argv[0],
            CLIENT_COMMAND,
            SERVER_COMMAND,
            HELP_COMMAND
        );
        fprintf(stderr, "Run '%s %s' for more information.\n", argv[0], HELP_COMMAND);
        return EXIT_FAILURE;
    }

    const char *command = argv[1];

    if (strcmp(command, HELP_COMMAND) == 0) {
        print_help(argv[0]);
        return EXIT_SUCCESS;
    }

    if (strcmp(command, CLIENT_COMMAND) == 0) {
        if (client_run(argc, argv, envp) != 0) {
            fprintf(stderr, "Failed to run client command.\n");
            return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
    }

    if (strcmp(command, SERVER_COMMAND) == 0) {
        if (server_run(argc, argv, envp) != 0) {
            fprintf(stderr, "Failed to run server command.\n");
            return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
    }

    fprintf(stderr, "Error: Unknown command '%s'\n", command);
    fprintf(stderr, "Run '%s %s' for available commands.\n", argv[0], HELP_COMMAND);
    return EXIT_FAILURE;
}
