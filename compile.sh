#!/bin/bash
if ! command -v pkg-config &> /dev/null; then
    echo "Error: pkg-config not found. Install it with: pacman -S mingw-w64-x86_64-pkgconf"
    exit 1
fi
SOURCE_FILE="generated_output.cpp"
OUTPUT_FILE="text_renderer.exe"
g++ -Wall -Wextra "$SOURCE_FILE" -o "$OUTPUT_FILE" $(pkg-config --libs --cflags freetype2 glfw3 glew) -lopengl32 -lgdi32
if [ $? -eq 0 ]; then
    echo "Compilation successful: $OUTPUT_FILE"
else
    echo "Compilation failed"
    exit 1
fi
