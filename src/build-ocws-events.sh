#!/usr/bin/env bash
# Build OCWS event bus C library

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
LIB_DIR="$OCWS_DIR/lib"
mkdir -p "$LIB_DIR"

cd "$(dirname "$0")"/../src
cat > Makefile << 'EOF'
CC = gcc
CFLAGS = -Wall -Wextra -O2 -fPIC -I.
LDFLAGS = -shared -lpthread -lm -ljson-c
TARGET = libocws-events.so
SRC = ocws-events.c ocws-config.c
OBJ = $(patsubst %.c,%.o,$(SRC))

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
	rm /usr/local/lib/libocws-events.so
	ldconfig

.PHONY: all clean install uninstall
EOF

echo "Building OCWS Event Bus..."

if make; then
    cp libocws-events.so "$LIB_DIR/"
    chmod +x "$LIB_DIR/libocws-events.so"
    echo "✓ Event Bus library built and installed to: $LIB_DIR/libocws-events.so"
else
    echo "Failed to build library."
    exit 1
fi