cmake_minimum_required(VERSION 3.10...4.3)

project(safar
    VERSION 0.1.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if (NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    add_subdirectory(tools)
endif()

add_subdirectory(src)
add_subdirectory(vendor/whisper.cpp)
