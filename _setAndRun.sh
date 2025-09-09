pacman -S --needed mingw-w64-x86_64-gcc \
                  mingw-w64-x86_64-cmake \
                  mingw-w64-x86_64-make \
                  mingw-w64-x86_64-clang \
                  mingw-w64-x86_64-zlib \
                  mingw-w64-x86_64-libpng \
                  mingw-w64-x86_64-bzip2 \
                  mingw-w64-x86_64-libbrotlidec \
                  mingw-w64-x86_64-freetype \
                  mingw-w64-x86_64-glfw \
                  mingw-w64-x86_64-glew \
                  mingw-w64-x86_64-libglvnd \
                  mingw-w64-x86_64-pkgconf \
                  mingw-w64-x86_64-git

# MSYS2 Bash script to set up and compile visualizer project
# Run in MSYS2 MinGW 64-bit shell: ./setup_visualizer.sh

# Ensure script is running in MSYS2 MinGW 64-bit environment
if [[ ! "$MSYSTEM" == "MINGW64" ]]; then
    echo "Please run this script in the MSYS2 MinGW 64-bit shell."
    exit 1
fi

# Step 1: Install MSYS2 dependencies
echo "Installing MSYS2 dependencies..."
pacman -Syu --noconfirm
pacman -S --noconfirm mingw-w64-x86_64-cmake mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-zlib mingw-w64-x86_64-libpng mingw-w64-x86_64-bzip2 mingw-w64-x86_64-glfw mingw-w64-x86_64-glew
pacman -S --noconfirm mingw-w64-x86_64-libbrotlidec || echo "libbrotlidec not found, proceeding without it"

# Step 2: Create project directories
PROJECT_DIR="/c/Users/selfd/Desktop/_"
LIB_DIR="$PROJECT_DIR/lib"
INCLUDE_DIR="$PROJECT_DIR/include"
echo "Creating project directories..."
mkdir -p "$LIB_DIR"
mkdir -p "$INCLUDE_DIR"

# Step 3: Copy GLFW, GLEW, and FreeType files
echo "Copying GLFW, GLEW, and FreeType files..."
cp -f /mingw64/lib/libglfw3.a "$LIB_DIR/" 2>/dev/null || echo "Failed to copy libglfw3.a"
cp -rf /mingw64/include/GLFW "$INCLUDE_DIR/" 2>/dev/null || echo "Failed to copy GLFW headers"
cp -f /mingw64/bin/glfw3.dll "$PROJECT_DIR/" 2>/dev/null || echo "Failed to copy glfw3.dll"
cp -f /mingw64/lib/libglew32.a "$LIB_DIR/" 2>/dev/null || echo "Failed to copy libglew32.a"
cp -rf /mingw64/include/GL "$INCLUDE_DIR/" 2>/dev/null || echo "Failed to copy GL headers"
cp -f /mingw64/bin/glew32.dll "$PROJECT_DIR/" 2>/dev/null || echo "Failed to copy glew32.dll"
cp -f /mingw64/bin/libfreetype-6.dll "$PROJECT_DIR/freetype.dll" 2>/dev/null || echo "Failed to copy libfreetype-6.dll"

# Step 4: Copy font
echo "Copying arial.ttf..."
FONT_SRC="/c/Windows/Fonts/arial.ttf"
FONT_DEST="$PROJECT_DIR/arial.ttf"
cp -f "$FONT_SRC" "$FONT_DEST" 2>/dev/null || echo "Failed to copy arial.ttf"

# Step 5: Create test.html
echo "Creating test.html..."
cat > "$PROJECT_DIR/test.html" << 'EOF'
<h1>hello world!!!</h1>
<div><p>my name is tiago and i am 37 years old!!!</p></div>
<div><p>nice to meet you    !!!</p></div>
EOF

# Step 6: Build FreeType 2.14.0
echo "Building FreeType 2.14.0..."
FREETYPE_DIR="/c/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0"
if [[ ! -d "$FREETYPE_DIR" ]]; then
    echo "Downloading FreeType 2.14.0..."
    mkdir -p "/c/Users/selfd/Downloads/openglStack/ft2140"
    curl -L "https://sourceforge.net/projects/freetype/files/freetype2/2.14.0/freetype-2.14.0.tar.gz" -o "/c/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0.tar.gz"
    tar -xzf "/c/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0.tar.gz" -C "/c/Users/selfd/Downloads/openglStack/ft2140"
fi
BUILD_DIR="$FREETYPE_DIR/builds"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake -G "MinGW Makefiles" -DCMAKE_INSTALL_PREFIX="$PROJECT_DIR" -DBUILD_SHARED_LIBS=OFF -DFT_WITH_ZLIB=ON -DFT_WITH_PNG=ON -DFT_WITH_BZIP2=ON -DFT_WITH_BROTLI=OFF ..
mingw32-make
mingw32-make install
cd - >/dev/null

# Step 7: Copy libraries to project lib directory (already in place, but ensure consistency)
echo "Copying libraries to project lib directory..."
cp -f "$PROJECT_DIR/lib/libfreetype.a" "$LIB_DIR/" 2>/dev/null || echo "Failed to copy libfreetype.a"

# Step 8: Compile visualizer.cpp
echo "Compiling visualizer.cpp..."
cd "$PROJECT_DIR"
g++ -o visualizer.exe visualizer.cpp -std=c++17 -I include -L lib -lglfw3 -lglew32 -lopengl32 -lfreetype
if [[ $? -eq 0 ]]; then
    echo "Successfully compiled visualizer.exe"
else
    echo "Compilation of visualizer.cpp failed"
    exit 1
fi

# Step 9: Run visualizer.exe
echo "Running visualizer.exe..."
./visualizer.exe test.html
if [[ $? -eq 0 ]]; then
    echo "Successfully ran visualizer.exe"
else
    echo "Failed to run visualizer.exe"
    exit 1
fi

# Step 10: Compile generated_output.cpp
echo "Compiling generated_output.cpp..."
g++ -o generated_output.exe generated_output.cpp -std=c++17 -I include -L lib -lglfw3 -lglew32 -lopengl32 -lfreetype
if [[ $? -eq 0 ]]; then
    echo "Successfully compiled generated_output.exe"
else
    echo "Compilation of generated_output.cpp failed"
    exit 1
fi

# Step 11: Run generated_output.exe
echo "Running generated_output.exe..."
./generated_output.exe
if [[ $? -eq 0 ]]; then
    echo "Successfully ran generated_output.exe"
else
    echo "Failed to run generated_output.exe"
    exit 1
fi

echo "Setup and compilation complete! Check for a window displaying text."

g++ ./html_parser.cpp test.html
./a.out
g++ ./visualizer.cpp

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
