cmake_minimum_required(VERSION 3.25...4.0)

project("safar" VERSION 0.1.0 LANGUAGES CXX)

# C++ standard for the entire project.
set(CMAKE_CXX_STANDARD          20)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS        OFF)

add_subdirectory("src")
# add_subdirectory("vendor/whisper.cpp")

add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE safar::libsafar)
