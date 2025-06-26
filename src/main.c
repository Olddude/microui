#include "client.h"
#include "server.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CLIENT_COMMAND "client"
#define SERVER_COMMAND "server"

int main(int argc, char **argv, char **envp) {
    const char *command = argv[1];
    if (argc < 2) {
        fprintf(stderr, "Usage: %s %s|%s\n", argv[0], CLIENT_COMMAND, SERVER_COMMAND);
        return EXIT_FAILURE;
    }
    if (strcmp(command, CLIENT_COMMAND) == 0) {
        if (client_run(argc, argv, envp) != 0) {
            fprintf(stderr, "Failed to run client command.\n");
            return EXIT_FAILURE;
        }
    }
    if (strcmp(command, SERVER_COMMAND) == 0) {
        if (server_run(argc, argv, envp) != 0) {
            fprintf(stderr, "Failed to run server command.\n");
            return EXIT_FAILURE;
        }
    }
    return EXIT_SUCCESS;
}
