#include "client.h"
#include "window.h"

int client_run(int argc, char **argv, char **envp) {
    return window_run(argc, argv, envp);
}
