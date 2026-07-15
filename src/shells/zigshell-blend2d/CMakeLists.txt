cmake_minimum_required(VERSION 3.20)
project(zigshell-blend2d-deps LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build Blend2D as a static library
set(BLEND2D_DIR ${CMAKE_SOURCE_DIR}/deps/blend2d)
set(ASMJIT_DIR ${CMAKE_SOURCE_DIR}/deps/asmjit)

# Disable Blend2D tests
set(BLEND2D_TEST OFF CACHE BOOL "" FORCE)

# Try to find asmjit, if not found build without JIT
if(EXISTS "${ASMJIT_DIR}/CMakeLists.txt")
    add_subdirectory(${ASMJIT_DIR} ${CMAKE_BINARY_DIR}/asmjit EXCLUDE_FROM_ALL)
    set(BLEND2D_DEPS asmjit)
    message(STATUS "Building with AsmJit JIT support")
else()
    set(BLEND2D_DEPS "")
    message(STATUS "Building without JIT (software renderer)")
endif()

add_subdirectory(${BLEND2D_DIR} ${CMAKE_BINARY_DIR}/blend2d EXCLUDE_FROM_ALL)

# Create an interface library that links both
add_library(blend2d_deps INTERFACE)
target_link_libraries(blend2d_deps INTERFACE blend2d ${BLEND2D_DEPS})
target_include_directories(blend2d_deps INTERFACE
    ${BLEND2D_DIR}
    ${ASMJIT_DIR}/src
)
