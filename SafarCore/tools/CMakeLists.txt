add_executable(quran_preprocess
    quran_preprocess/main.cpp
)

set(GENERATED_HEADER ${CMAKE_SOURCE_DIR}/src/include/corpus.hpp)
set(GENERATED_SOURCE ${CMAKE_SOURCE_DIR}/src/corpus.cpp)
set(CORPUS_INPUT ${CMAKE_SOURCE_DIR}/data/quran/quran-uthmani.txt)

add_custom_command(
    OUTPUT
        ${GENERATED_HEADER}
        ${GENERATED_SOURCE}
    COMMAND
        ${CMAKE_COMMAND} -E make_directory
        ${CMAKE_SOURCE_DIR}/src/include
    COMMAND
        $<TARGET_FILE:quran_preprocess>
        ${CORPUS_INPUT}
        ${CMAKE_SOURCE_DIR}/src
    DEPENDS
        quran_preprocess
        ${CORPUS_INPUT}
    COMMENT "Generating Quran corpus from Tanzil source"
    VERBATIM
)

add_custom_target(generate_corpus
    DEPENDS
        ${GENERATED_HEADER}
        ${GENERATED_SOURCE}
)
