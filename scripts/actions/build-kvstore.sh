#!/bin/bash
# Compile and install the C key-value store library for OCWS
#
# This script builds libocws-kvstore.so from the C source code

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
LIB_DIR="$OCWS_DIR/lib"
mkdir -p "$LIB_DIR"

# Build the C library
cd "$(dirname "$0")"
cd ".."

cat > Makefile << 'EOF'
CC = gcc
CFLAGS = -Wall -Wextra -O2 -fPIC -I.
LDFLAGS = -shared -lrt
TARGET = libocws-kvstore.so
SRC = ocws-kvstore.c
OBJ = $(SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o *.so

install:
	cp $(TARGET) /usr/local/lib/
	ldconfig

uninstall:
	rm /usr/local/lib/libocws-kvstore.so
	ldconfig

.PHONY: all clean install uninstall
EOF

echo "Building C key-value store library..."
if make; then
    cp libocws-kvstore.so "$LIB_DIR/"
    chmod +x "$LIB_DIR/libocws-kvstore.so"
    echo "Library built and installed to: $LIB_DIR/libocws-kvstore.so"
else
    echo "Failed to build library. Check Makefile and source code."
    exit 1
fi