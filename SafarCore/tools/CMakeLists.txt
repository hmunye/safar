add_executable(quran_preprocess
    quran_preprocess/main.cpp
)

set(GENERATED_HEADER ${CMAKE_BINARY_DIR}/generated/corpus.hpp)
set(GENERATED_SOURCE ${CMAKE_BINARY_DIR}/generated/corpus.cpp)
set(CORPUS_INPUT ${CMAKE_SOURCE_DIR}/data/quran/quran-uthmani.txt)

add_custom_command(
    OUTPUT
        ${GENERATED_HEADER}
        ${GENERATED_SOURCE}
    COMMAND
        ${CMAKE_COMMAND} -E make_directory
        ${CMAKE_BINARY_DIR}/generated
    COMMAND
        $<TARGET_FILE:quran_preprocess>
        ${CORPUS_INPUT}
        ${CMAKE_BINARY_DIR}/generated
    DEPENDS
        quran_preprocess
        ${CORPUS_INPUT}
    COMMENT "Generating corpus files from quran-uthmani.txt"
    VERBATIM
)

add_custom_target(generate_corpus
    DEPENDS
        ${GENERATED_HEADER}
        ${GENERATED_SOURCE}
)
