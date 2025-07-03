#include "window.h"
#include "microui.h"
#include "renderer.h"
#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// Chat message structure
typedef struct
{
    char content[1024];
    int is_user;
    char timestamp[32];
} ChatMessage;

// Application state
static ChatMessage messages[100];
static int message_count = 0;
static char input_buffer[512] = "";
static char model_name[64] = "GPT-4";
static float temperature = 0.7f;
static int max_tokens = 2048;
static float bg[3] = {18, 18, 18}; // Dark theme background

// Utility functions
static void get_current_time(char *buffer, size_t size) {
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    strftime(buffer, size, "%H:%M", tm_info);
}

static void add_message(const char *content, int is_user) {
    if (message_count >= 100) {
        // Shift messages if we're at capacity
        for (int i = 0; i < 99; i++) {
            messages[i] = messages[i + 1];
        }
        message_count = 99;
    }

    strncpy(messages[message_count].content, content, sizeof(messages[message_count].content) - 1);
    messages[message_count].content[sizeof(messages[message_count].content) - 1] = '\0';
    messages[message_count].is_user = is_user;
    get_current_time(messages[message_count].timestamp, sizeof(messages[message_count].timestamp));
    message_count++;
}

static void simulate_ai_response(const char *user_input) {
    // Simple AI response simulation
    const char *responses[] = {
        "I understand your question. Let me help you with that.",
        "That's an interesting point. Here's what I think about it:",
        "Based on your input, I would suggest the following approach:",
        "I can help you explore this topic further. Consider these aspects:",
        "That's a great question! Let me break it down for you:"
    };

    char response[1024];
    int response_idx = rand() % (sizeof(responses) / sizeof(responses[0]));
    snprintf(
        response,
        sizeof(response),
        "%s\n\nRegarding '%s' - this is a simulated response that would normally come from an AI "
        "model. In a real implementation, this would connect to an actual AI service.",
        responses[response_idx],
        user_input
    );

    add_message(response, 0); // 0 = AI response
}

// Main chat interface
static void chat_window(mu_Context *ctx) {
    if (mu_begin_window(ctx, "OpenAI Chat Interface", mu_rect(50, 50, 1300, 650))) {
        mu_Container *win = mu_get_current_container(ctx);
        win->rect.w = mu_max(win->rect.w, 1200);
        win->rect.h = mu_max(win->rect.h, 600);

        // Top bar with model selection and settings
        if (mu_header_ex(ctx, "Model Configuration", 0)) {
            mu_layout_row(ctx, 3, (int[]) {120, 150, -1}, 0);
            mu_label(ctx, "Model:");
            mu_label(ctx, model_name);
            if (mu_button(ctx, "Settings")) {
                // Settings would be handled here
            }
        }

        // Chat messages area
        mu_layout_row(ctx, 1, (int[]) {-1}, -80);
        mu_begin_panel(ctx, "Chat Messages");

        for (int i = 0; i < message_count; i++) {
            mu_layout_row(ctx, 1, (int[]) {-1}, 0);

            // Message header with timestamp and sender
            char header[128];
            snprintf(
                header,
                sizeof(header),
                "%s - %s",
                messages[i].is_user ? "You" : "Assistant",
                messages[i].timestamp
            );

            // Different styling for user vs AI messages
            if (messages[i].is_user) {
                mu_push_id(ctx, &i, sizeof(i));
                mu_draw_rect(ctx, mu_layout_next(ctx), mu_color(40, 40, 60, 100));
                mu_pop_id(ctx);
                mu_layout_row(ctx, 1, (int[]) {-1}, 0);
            }

            mu_text(ctx, header);
            mu_text(ctx, messages[i].content);
            mu_text(ctx, ""); // Empty line for spacing
        }

        mu_end_panel(ctx);

        // Input area at bottom
        mu_layout_row(ctx, 1, (int[]) {-1}, 60);
        mu_begin_panel(ctx, "Input Area");

        mu_layout_row(ctx, 2, (int[]) {-80, 70}, 0);
        int input_result = mu_textbox(ctx, input_buffer, sizeof(input_buffer));

        int send_pressed = mu_button(ctx, "Send");

        if ((input_result & MU_RES_SUBMIT) || send_pressed) {
            if (strlen(input_buffer) > 0) {
                add_message(input_buffer, 1); // 1 = user message
                simulate_ai_response(input_buffer);
                input_buffer[0] = '\0'; // Clear input
                mu_set_focus(ctx, ctx->last_id);
            }
        }

        mu_end_panel(ctx);
        mu_end_window(ctx);
    }
}

// Settings panel
static void settings_window(mu_Context *ctx) {
    if (mu_begin_window(ctx, "Settings", mu_rect(1370, 50, 500, 400))) {
        // Model settings
        if (mu_header_ex(ctx, "Model Parameters", MU_OPT_EXPANDED)) {
            mu_layout_row(ctx, 2, (int[]) {100, -1}, 0);

            mu_label(ctx, "Temperature:");
            mu_slider(ctx, &temperature, 0.0f, 2.0f);

            mu_label(ctx, "Max Tokens:");
            float max_tokens_float = (float) max_tokens;
            mu_slider_ex(ctx, &max_tokens_float, 1, 4096, 1, "%.0f", MU_OPT_ALIGNCENTER);
            max_tokens = (int) max_tokens_float;
        }

        // Theme settings
        if (mu_header_ex(ctx, "Theme", MU_OPT_EXPANDED)) {
            mu_layout_row(ctx, 2, (int[]) {80, -1}, 0);
            mu_label(ctx, "Background:");
            mu_layout_row(ctx, 3, (int[]) {60, 60, 60}, 0);
            mu_slider_ex(ctx, &bg[0], 0, 255, 1, "%.0f", MU_OPT_ALIGNCENTER);
            mu_slider_ex(ctx, &bg[1], 0, 255, 1, "%.0f", MU_OPT_ALIGNCENTER);
            mu_slider_ex(ctx, &bg[2], 0, 255, 1, "%.0f", MU_OPT_ALIGNCENTER);
        }

        // Actions
        mu_layout_row(ctx, 2, (int[]) {-1, -1}, 0);
        if (mu_button(ctx, "Clear Chat")) {
            message_count = 0;
        }
        if (mu_button(ctx, "Export Chat")) {
            // Export functionality would go here
        }

        mu_end_window(ctx);
    }
}

// Status bar showing connection info and stats
static void status_bar(mu_Context *ctx) {
    if (mu_begin_window(ctx, "Status", mu_rect(50, 710, 1300, 40))) {
        mu_Container *win = mu_get_current_container(ctx);
        win->rect.w = mu_max(win->rect.w, 1200);

        mu_layout_row(ctx, 4, (int[]) {150, 150, 150, -1}, 0);

        char status_text[64];
        snprintf(status_text, sizeof(status_text), "Messages: %d", message_count);
        mu_label(ctx, status_text);

        snprintf(status_text, sizeof(status_text), "Model: %s", model_name);
        mu_label(ctx, status_text);

        snprintf(status_text, sizeof(status_text), "Temp: %.1f", temperature);
        mu_label(ctx, status_text);

        mu_label(ctx, "Status: Ready");

        mu_end_window(ctx);
    }
}

// Main frame processing
static void process_frame(mu_Context *ctx) {
    mu_begin(ctx);
    chat_window(ctx);
    settings_window(ctx);
    status_bar(ctx);
    mu_end(ctx);
}

static const char button_map[256] = {
    [SDL_BUTTON_LEFT & 0xff] = MU_MOUSE_LEFT,
    [SDL_BUTTON_RIGHT & 0xff] = MU_MOUSE_RIGHT,
    [SDL_BUTTON_MIDDLE & 0xff] = MU_MOUSE_MIDDLE,
};

static const char key_map[256] = {
    [SDLK_LSHIFT & 0xff] = MU_KEY_SHIFT,
    [SDLK_RSHIFT & 0xff] = MU_KEY_SHIFT,
    [SDLK_LCTRL & 0xff] = MU_KEY_CTRL,
    [SDLK_RCTRL & 0xff] = MU_KEY_CTRL,
    [SDLK_LALT & 0xff] = MU_KEY_ALT,
    [SDLK_RALT & 0xff] = MU_KEY_ALT,
    [SDLK_RETURN & 0xff] = MU_KEY_RETURN,
    [SDLK_BACKSPACE & 0xff] = MU_KEY_BACKSPACE,
};

static int text_width(mu_Font font, const char *text, int len) {
    if (len == -1) {
        len = strlen(text);
    }
    return r_get_text_width(text, len);
}

static int text_height(mu_Font font) {
    return r_get_text_height();
}

int window_command_run(int argc, char **argv, char **envp) {
    /* init SDL and renderer */
    SDL_Init(SDL_INIT_EVERYTHING);
    r_init();

    /* init microui */
    mu_Context *ctx = malloc(sizeof(mu_Context));
    mu_init(ctx);
    ctx->text_width = text_width;
    ctx->text_height = text_height;

    /* Seed random number generator */
    srand(time(NULL));

    /* Add welcome message */
    add_message(
        "Welcome to the OpenAI-style Chat Interface! This is a demonstration of a modern chat UI "
        "built with microui. You can type messages and receive simulated AI responses.",
        0
    );

    /* main loop */
    for (;;) {
        /* handle SDL events */
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            switch (e.type) {
            case SDL_QUIT:
                free(ctx);
                exit(EXIT_SUCCESS);
                break;
            case SDL_MOUSEMOTION:
                mu_input_mousemove(ctx, e.motion.x, e.motion.y);
                break;
            case SDL_MOUSEWHEEL:
                mu_input_scroll(ctx, 0, e.wheel.y * -30);
                break;
            case SDL_TEXTINPUT:
                mu_input_text(ctx, e.text.text);
                break;

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP: {
                int b = button_map[e.button.button & 0xff];
                if (b && e.type == SDL_MOUSEBUTTONDOWN) {
                    mu_input_mousedown(ctx, e.button.x, e.button.y, b);
                }
                if (b && e.type == SDL_MOUSEBUTTONUP) {
                    mu_input_mouseup(ctx, e.button.x, e.button.y, b);
                }
                break;
            }

            case SDL_KEYDOWN:
            case SDL_KEYUP: {
                int c = key_map[e.key.keysym.sym & 0xff];
                if (c && e.type == SDL_KEYDOWN) {
                    mu_input_keydown(ctx, c);
                }
                if (c && e.type == SDL_KEYUP) {
                    mu_input_keyup(ctx, c);
                }
                break;
            }
            }
        }

        /* process frame */
        process_frame(ctx);

        /* render */
        r_clear(mu_color(bg[0], bg[1], bg[2], 255));
        mu_Command *cmd = NULL;
        while (mu_next_command(ctx, &cmd)) {
            switch (cmd->type) {
            case MU_COMMAND_TEXT:
                r_draw_text(cmd->text.str, cmd->text.pos, cmd->text.color);
                break;
            case MU_COMMAND_RECT:
                r_draw_rect(cmd->rect.rect, cmd->rect.color);
                break;
            case MU_COMMAND_ICON:
                r_draw_icon(cmd->icon.id, cmd->icon.rect, cmd->icon.color);
                break;
            case MU_COMMAND_CLIP:
                r_set_clip_rect(cmd->clip.rect);
                break;
            }
        }
        r_present();
    }

    return 0;
}
