add_library(libsafar STATIC
    libsafar.cpp
    model.cpp
    normalize.cpp
    match.cpp
)
add_library(safar::libsafar ALIAS libsafar)

# Produce libsafar.a instead of liblibsafar.a.
set_target_properties(libsafar PROPERTIES
    OUTPUT_NAME safar
)

add_dependencies(libsafar generate_corpus)
target_sources(libsafar
    PRIVATE
        ${CMAKE_BINARY_DIR}/generated/corpus.cpp
)

target_compile_features(libsafar PUBLIC cxx_std_20)
target_compile_options(libsafar PUBLIC
    -Wall 
    -Wextra 
    -Werror 
    -Wpedantic
    -Wno-error=overlength-strings
)

target_include_directories(libsafar
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_BINARY_DIR}/generated
)

target_link_libraries(libsafar
    PRIVATE
        whisper
)
