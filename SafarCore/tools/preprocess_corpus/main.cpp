#include "normalize.hpp"

#include <cstdint>
#include <cstdlib>
#include <exception>
#include <fstream>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

struct Entry {
    std::string text;
    std::uint16_t surah;
    std::uint16_t ayah;
};

std::optional<Entry> parse_line(const std::string& line, int line_number) {
    if (line.empty() || line[0] == '#') {
        return std::nullopt;
    }

    std::size_t pos_surah{ line.find('|') };
    if (pos_surah == std::string::npos) {
        std::cerr << "error: line " << line_number << " malformed: " << line
                  << "\n";
        std::exit(1);
    }

    std::size_t pos_ayah{ line.find('|', pos_surah + 1) };
    if (pos_ayah == std::string::npos) {
        std::cerr << "error: line " << line_number << " malformed: " << line
                  << "\n";
        std::exit(1);
    }

    Entry entry;

    try {
        entry.surah =
            static_cast<uint16_t>(std::stoi(line.substr(0, pos_surah)));

        entry.ayah = static_cast<uint16_t>(
            std::stoi(line.substr(pos_surah + 1, pos_ayah)));
    } catch (const std::exception&) {
        std::cerr << "error: line " << line_number
                  << "; invalid surah/ayah number: " << line << "\n";
        std::exit(1);
    }

    entry.text = line.substr(pos_ayah + 1);

    return entry;
}

std::vector<Entry> read_input(const std::string& path) {
    std::ifstream in(path);
    if (!in.is_open()) {
        std::cerr << "error: failed to open input file: " << path << "\n";
        std::exit(1);
    }

    std::vector<Entry> entries;
    std::string line;

    for (std::size_t i{ 1 }; std::getline(in, line); ++i) {
        auto entry = parse_line(line, i);
        if (entry) {
            entries.push_back(std::move(*entry));
        }
    }

    return entries;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: " << argv[0] << " <input.txt> <output-dir>\n";
        return 1;
    }

    const std::string input_path{ argv[1] };
    const std::string output_dir{ argv[2] };

    auto entries = read_input(input_path);
    auto header_path = output_dir + "/corpus.hpp";
    auto source_path = output_dir + "/corpus.cpp";

    std::ofstream header(header_path);
    if (!header.is_open()) {
        std::cerr << "error: failed to write header file: " << header_path
                  << "\n";
        return 1;
    }

    header << "// AUTO-GENERATED FILE - DO NOT EDIT\n";
    header << "#pragma once\n\n";
    header << "#include <cstdint>\n";
    header << "#include <string_view>\n\n";
    header << "namespace safar {\n\n";
    header << "struct CorpusEntry {\n";
    header << "    std::string_view original;\n";
    header << "    std::string_view normalized;\n";
    header << "    std::uint16_t surah;\n";
    header << "    std::uint16_t ayah;\n";
    header << "};\n\n";
    header << "extern const CorpusEntry corpus[];\n";
    header << "}  // namespace safar";

    header.close();

    std::ofstream source(source_path);
    if (!source.is_open()) {
        std::cerr << "error: failed to write source file: " << source_path
                  << "\n";
        return 1;
    }

    source << "// AUTO-GENERATED FILE - DO NOT EDIT\n";
    source << "#include \"corpus.hpp\"\n\n";
    source << "namespace safar {\n\n";
    source << "const CorpusEntry corpus[] = {\n";

    for (const auto& e : entries) {
        source << "    {\"" << e.text << "\", " << "\""
               << safar::normalize_text(e.text) << "\", " << e.surah << ", "
               << e.ayah << "},\n";
    }

    source << "};\n\n";
    source << "}  // namespace safar";

    source.close();
}
