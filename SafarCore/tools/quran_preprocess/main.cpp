#include <cstdint>
#include <cstdlib>
#include <exception>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

struct VerseEntry {
    std::uint16_t surah;
    std::uint16_t ayah;
    std::string text;
};

bool parse_line(const std::string& line, int line_number, VerseEntry& out) {
    if (line.empty() || line[0] == '#') {
        return false;
    }

    std::size_t pipe_1 = line.find('|');
    if (pipe_1 == std::string::npos) {
        std::cerr << "error: malformed line " << line_number << ": " << line
                  << "\n";
        std::exit(1);
    }

    std::size_t pipe_2 = line.find('|', pipe_1 + 1);
    if (pipe_2 == std::string::npos) {
        std::cerr << "error: malformed line " << line_number << ": " << line
                  << "\n";
        std::exit(1);
    }

    std::string surah_str = line.substr(0, pipe_1);
    std::string ayah_str = line.substr(pipe_1 + 1, pipe_2);

    try {
        out.surah = static_cast<uint16_t>(std::stoi(surah_str));
        out.ayah = static_cast<uint16_t>(std::stoi(ayah_str));
    } catch (const std::exception&) {
        std::cerr << "error: invalid surah/ayah number on line " << line_number
                  << ": " << line << "\n";
        std::exit(1);
    }

    out.text = line.substr(pipe_2 + 1);
    return true;
}

std::vector<VerseEntry> read_input(const std::string& file_path) {
    std::ifstream in(file_path);
    if (!in.is_open()) {
        std::cerr << "error: failed to open input file: " << file_path << "\n";
        std::exit(1);
    }

    std::vector<VerseEntry> entries;
    std::string line;

    int line_number = 0;
    while (std::getline(in, line)) {
        VerseEntry entry;
        if (parse_line(line, ++line_number, entry)) {
            entries.push_back(std::move(entry));
        }
    }

    return entries;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: " << argv[0] << " <input.txt> <output-dir>\n";
        return 1;
    }

    const std::string input_path = argv[1];
    const std::string output_dir = argv[2];

    std::vector<VerseEntry> entries = read_input(input_path);

    std::ofstream header(output_dir + "/corpus.hpp");
    if (!header.is_open()) {
        std::cerr << "error: failed to write header file: " << "\n";
        return 1;
    }

    header << "// AUTO-GENERATED FILE - DO NOT EDIT\n";
    header << "#pragma once\n\n";
    header << "#include <cstddef>\n";
    header << "#include <cstdint>\n";
    header << "#include <string_view>\n\n";
    header << "namespace safar {\n\n";
    header << "struct VerseEntry {\n";
    header << "    std::string_view text;\n";
    header << "    std::uint16_t surah;\n";
    header << "    std::uint16_t ayah;\n";
    header << "};\n\n";
    header << "extern const VerseEntry quran_corpus[];\n";
    header << "extern const std::size_t quran_corpus_size;\n\n";
    header << "}  // namespace safar";

    header.close();

    std::ofstream source(output_dir + "/corpus.cpp");
    if (!source.is_open()) {
        std::cerr << "error: failed to write source file: " << "\n";
        return 1;
    }

    source << "// AUTO-GENERATED FILE - DO NOT EDIT\n";
    source << "#include \"corpus.hpp\"\n\n";
    source << "#include <iterator>\n\n";
    source << "namespace safar {\n\n";
    source << "const VerseEntry quran_corpus[] = {\n";

    for (const auto& e : entries) {
        source << "    {\"" << e.text << "\", " << e.surah << ", " << e.ayah
               << "},\n";
    }

    source << "};\n\n";
    source
        << "const std::size_t quran_corpus_size = std::size(quran_corpus);\n\n";
    source << "}  // namespace safar";

    source.close();

    return 0;
}
