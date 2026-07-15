add_library(libsafar STATIC libsafar.cpp)
add_library(safar::libsafar ALIAS libsafar)

# Set library output name to `libsafar.a` (defaults to `liblibsafar.a`).
set_target_properties(
    libsafar
    PROPERTIES OUTPUT_NAME safar
)

target_compile_options(libsafar PUBLIC
    -Wall 
    -Wextra 
    -Werror 
    -Wpedantic
    $<$<CONFIG:RELEASE>:-O3>
    $<$<CONFIG:DEBUG>:-ggdb>
)

target_include_directories(libsafar
    # PUBLIC: Targets that compile against `libsafar` will inherit the generated
    # include paths.
    PUBLIC
        $<INSTALL_INTERFACE:include>
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    # PRIVATE: Targets that compile against `libsafar` will not depend on the
    # local `include/` directory.
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/include
)
