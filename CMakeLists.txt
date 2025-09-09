```cmake
cmake_minimum_required(VERSION 3.20)
project(VisualizerProject LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Ensure MSYS2 MinGW 64-bit environment
if(NOT MSYS OR NOT MINGW)
    message(FATAL_ERROR "This project requires MSYS2 MinGW 64-bit environment. Please run in MSYS2 MinGW 64-bit shell.")
endif()

# Verify compiler availability
find_program(GCC_EXECUTABLE gcc)
find_program(GXX_EXECUTABLE g++)
if(NOT GCC_EXECUTABLE OR NOT GXX_EXECUTABLE)
    message(FATAL_ERROR "GCC/G++ not found. Ensure mingw-w64-x86_64-gcc is installed and in PATH.")
endif()

# Define project directories
set(PROJECT_DIR "${CMAKE_SOURCE_DIR}")
set(LIB_DIR "${PROJECT_DIR}/lib")
set(INCLUDE_DIR "${PROJECT_DIR}/include")
file(MAKE_DIRECTORY "${LIB_DIR}" "${INCLUDE_DIR}")

# Find required packages
find_package(PkgConfig REQUIRED)
find_package(OpenGL REQUIRED)
pkg_check_modules(FREETYPE REQUIRED freetype2)
pkg_check_modules(GLFW REQUIRED glfw3)
pkg_check_modules(GLEW REQUIRED glew)

# Copy GLFW, GLEW, and FreeType files
foreach(_file
    "/mingw64/lib/libglfw3.a:${LIB_DIR}"
    "/mingw64/include/GLFW:${INCLUDE_DIR}"
    "/mingw64/bin/glfw3.dll:${PROJECT_DIR}"
    "/mingw64/lib/libglew32.a:${LIB_DIR}"
    "/mingw64/include/GL:${INCLUDE_DIR}"
    "/mingw64/bin/glew32.dll:${PROJECT_DIR}"
    "/mingw64/bin/libfreetype-6.dll:${PROJECT_DIR}/freetype.dll")
    string(REPLACE ":" ";" _file_pair ${_file})
    list(GET _file_pair 0 _src)
    list(GET _file_pair 1 _dest)
    if(IS_DIRECTORY ${_src})
        file(COPY ${_src} DESTINATION ${_dest})
    else()
        file(COPY ${_src} DESTINATION ${_dest} FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    endif()
endforeach()

# Copy Arial font
set(FONT_SRC "C:/Windows/Fonts/arial.ttf")
set(FONT_DEST "${PROJECT_DIR}/arial.ttf")
if(EXISTS "${FONT_SRC}")
    file(COPY "${FONT_SRC}" DESTINATION "${PROJECT_DIR}")
else()
    message(WARNING "Arial font not found at ${FONT_SRC}. Skipping copy.")
endif()

# Create test.html
file(WRITE "${PROJECT_DIR}/test.html"
"<h1>hello world!!!</h1>
<div><p>my name is tiago and i am 37 years old!!!</p></div>
<div><p>nice to meet you    !!!</p></div>")

# Build FreeType 2.14.0
set(FREETYPE_DIR "C:/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0")
if(NOT EXISTS "${FREETYPE_DIR}")
    message(STATUS "Downloading FreeType 2.14.0...")
    file(MAKE_DIRECTORY "C:/Users/selfd/Downloads/openglStack/ft2140")
    file(DOWNLOAD
        "https://sourceforge.net/projects/freetype/files/freetype2/2.14.0/freetype-2.14.0.tar.gz"
        "C:/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0.tar.gz"
        SHOW_PROGRESS
    )
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "C:/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0.tar.gz"
        WORKING_DIRECTORY "C:/Users/selfd/Downloads/openglStack/ft2140"
        RESULT_VARIABLE _result
    )
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "Failed to extract FreeType 2.14.0 tarball.")
    endif()
endif()

set(FREETYPE_BUILD_DIR "${FREETYPE_DIR}/builds")
file(MAKE_DIRECTORY "${FREETYPE_BUILD_DIR}")
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -G "MinGW Makefiles"
        -DCMAKE_INSTALL_PREFIX=${PROJECT_DIR}
        -DBUILD_SHARED_LIBS=OFF
        -DFT_WITH_ZLIB=ON
        -DFT_WITH_PNG=ON
        -DFT_WITH_BZIP2=ON
        -DFT_WITH_BROTLI=OFF
        ..
    WORKING_DIRECTORY "${FREETYPE_BUILD_DIR}"
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "CMake configuration for FreeType failed.")
endif()
execute_process(
    COMMAND ${CMAKE_MAKE_PROGRAM}
    WORKING_DIRECTORY "${FREETYPE_BUILD_DIR}"
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Build of FreeType failed.")
endif()
execute_process(
    COMMAND ${CMAKE_MAKE_PROGRAM} install
    WORKING_DIRECTORY "${FREETYPE_BUILD_DIR}"
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Installation of FreeType failed.")
endif()

# Copy FreeType library
file(COPY "${PROJECT_DIR}/lib/libfreetype.a" DESTINATION "${LIB_DIR}")

# Compile visualizer executable
add_executable(visualizer visualizer.cpp)
target_include_directories(visualizer PRIVATE "${INCLUDE_DIR}" ${FREETYPE_INCLUDE_DIRS} ${GLFW_INCLUDE_DIRS} ${GLEW_INCLUDE_DIRS})
target_link_directories(visualizer PRIVATE "${LIB_DIR}")
target_link_libraries(visualizer PRIVATE glfw3 glew32 ${OPENGL_LIBRARIES} freetype)

# Run visualizer
add_custom_command(TARGET visualizer POST_BUILD
    COMMAND $<TARGET_FILE:visualizer> "${PROJECT_DIR}/test.html"
    WORKING_DIRECTORY "${PROJECT_DIR}"
    COMMENT "Running visualizer.exe..."
)

# Compile generated_output executable
add_executable(generated_output generated_output.cpp)
target_include_directories(generated_output PRIVATE "${INCLUDE_DIR}" ${FREETYPE_INCLUDE_DIRS} ${GLFW_INCLUDE_DIRS} ${GLEW_INCLUDE_DIRS})
target_link_directories(generated_output PRIVATE "${LIB_DIR}")
target_link_libraries(generated_output PRIVATE glfw3 glew32 ${OPENGL_LIBRARIES} freetype)

# Run generated_output
add_custom_command(TARGET generated_output POST_BUILD
    COMMAND $<TARGET_FILE:generated_output>
    WORKING_DIRECTORY "${PROJECT_DIR}"
    COMMENT "Running generated_output.exe..."
)

# Compile html_parser and run
add_executable(html_parser html_parser.cpp)
add_custom_command(TARGET html_parser POST_BUILD
    COMMAND $<TARGET_FILE:html_parser> "${PROJECT_DIR}/test.html"
    WORKING_DIRECTORY "${PROJECT_DIR}"
    COMMENT "Running html_parser..."
)

# Compile text_renderer executable
add_executable(text_renderer generated_output.cpp)
target_include_directories(text_renderer PRIVATE "${INCLUDE_DIR}" ${FREETYPE_INCLUDE_DIRS} ${GLFW_INCLUDE_DIRS} ${GLEW_INCLUDE_DIRS})
target_link_libraries(text_renderer PRIVATE ${FREETYPE_LIBRARIES} ${GLFW_LIBRARIES} ${GLEW_LIBRARIES} ${OPENGL_LIBRARIES} gdi32)
target_compile_options(text_renderer PRIVATE -Wall -Wextra)
```