# microui

A *tiny*, portable, immediate-mode app in ANSI C

## Environment

The content of your [.env](.env) file should be as bellow

```bash
PREFIX='/usr/local'
BUILD_TYPE='Debug'
```

## Configuration

See [microui.conf](microui.conf)

## Build

See [Makefile](Makefile)

## Features

* Tiny: around `1100 sloc` of ANSI C
* Works within a fixed-sized memory region: no additional memory is allocated
* Built-in controls: window, scrollable panel, button, slider, textbox, label,
  checkbox, wordwrapped text
* Works with any rendering system that can draw rectangles and text
* Designed to allow the user to easily add custom controls
* Simple layout system

## Example

```c
if (mu_begin_window(ctx, "My Window", mu_rect(10, 10, 140, 86))) {
  mu_layout_row(ctx, 2, (int[]) { 60, -1 }, 0);

  mu_label(ctx, "First:");
  if (mu_button(ctx, "Button1")) {
    printf("Button1 pressed\n");
  }

  mu_label(ctx, "Second:");
  if (mu_button(ctx, "Button2")) {
    mu_open_popup(ctx, "My Popup");
  }

  if (mu_begin_popup(ctx, "My Popup")) {
    mu_label(ctx, "Hello world!");
    mu_end_popup(ctx);
  }

  mu_end_window(ctx);
}
```

## Usage

* See [doc/usage.md](doc/usage.md) for usage instructions

## Notes

The library expects the user to provide input and handle the resultant drawing
commands, it does not do any drawing itself.

## License

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
