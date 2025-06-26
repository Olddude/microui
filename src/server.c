#include <stdio.h>
#include <unistd.h>

// static int shutdown_requested = 0;

int server_run(int argc, char **argv, char **envp) {
    // while (!shutdown_requested) {
    //     sleep(1);
    //     printf("Server is running...\n");
    // }
    printf("Server started...\n");
    return 0;
}
