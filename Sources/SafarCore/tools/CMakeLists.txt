add_executable(preprocess_corpus
    preprocess_corpus/main.cpp
    ${CMAKE_SOURCE_DIR}/src/normalize.cpp
)

target_include_directories(preprocess_corpus
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/include
)

set(GENERATED_HEADER ${CMAKE_BINARY_DIR}/generated/corpus.hpp)
set(GENERATED_SOURCE ${CMAKE_BINARY_DIR}/generated/corpus.cpp)
set(CORPUS_INPUT ${CMAKE_SOURCE_DIR}/data/quran/quran-uthmani.txt)
set(TRANSLATION_INPUT ${CMAKE_SOURCE_DIR}/data/quran/quran_en_hilali.txt)

add_custom_command(
    OUTPUT
        ${GENERATED_HEADER}
        ${GENERATED_SOURCE}
    COMMAND
        ${CMAKE_COMMAND} -E make_directory
        ${CMAKE_BINARY_DIR}/generated
    COMMAND
        $<TARGET_FILE:preprocess_corpus>
        ${CORPUS_INPUT}
        ${TRANSLATION_INPUT}
        ${CMAKE_BINARY_DIR}/generated
    DEPENDS
        preprocess_corpus
        ${CORPUS_INPUT}
        ${TRANSLATION_INPUT}
    COMMENT "Generating corpus files from quran-uthmani.txt/quran_en_hilali.txt"
    VERBATIM
)

add_custom_target(generate_corpus
    DEPENDS
        ${GENERATED_HEADER}
        ${GENERATED_SOURCE}
)
