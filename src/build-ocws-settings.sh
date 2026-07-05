#!/bin/sh
gcc -O3 $(pkg-config --cflags gtk+-3.0) src/ocws-settings.c -o ~/.local/bin/ocws-settings $(pkg-config --libs gtk+-3.0)
echo "Compiled ocws-settings successfully to ~/.local/bin/ocws-settings"
