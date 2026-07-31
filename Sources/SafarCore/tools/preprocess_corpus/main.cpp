#include "normalize.hpp"

#include <cstdint>
#include <cstdlib>
#include <exception>
#include <filesystem>
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

struct Offset {
    std::size_t offset;
    std::size_t length;
};

std::string escape_cpp(std::string_view s) {
    std::string out;

    for (char c : s) {
        switch (c) {
            case '\\':
                out += "\\\\";
                break;
            case '"':
                out += "\\\"";
                break;
            case '\n':
                out += "\\n";
                break;
            case '\r':
                out += "\\r";
                break;
            case '\t':
                out += "\\t";
                break;
            default:
                out += c;
        }
    }

    return out;
}

bool validate_order(const std::vector<Entry>& entries, std::string_view name) {
    for (std::size_t i{ 1 }; i < entries.size(); ++i) {
        const auto& prev = entries[i - 1];
        const auto& curr = entries[i];

        if (curr.surah < prev.surah ||
            (curr.surah == prev.surah && curr.ayah <= prev.ayah)) {
            std::cerr << "error: " << name << " order malformed: " << curr.surah
                      << ':' << curr.ayah << '\n';
            return false;
        }
    }

    return true;
}

std::optional<Entry> parse_line(const std::string& line, int line_number) {
    if (line.empty() || line[0] == '#') {
        return std::nullopt;
    }

    const std::size_t pos_surah{ line.find('|') };
    if (pos_surah == std::string::npos) {
        std::cerr << "error: line " << line_number << " malformed: " << line
                  << "\n";
        std::exit(1);
    }

    const std::size_t pos_ayah{ line.find('|', pos_surah + 1) };
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
            std::stoi(line.substr(pos_surah + 1, pos_ayah - pos_surah - 1)));
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
    if (argc != 4) {
        std::cerr << "usage: " << argv[0]
                  << " <input.txt> <translation.txt> <output-dir>\n";
        return 1;
    }

    const std::string input_path{ argv[1] };
    const std::string translation_path{ argv[2] };
    const std::filesystem::path output_dir{ argv[3] };

    const auto entries = read_input(input_path);
    const auto translations = read_input(translation_path);

    if (!validate_order(entries, "corpus") ||
        !validate_order(translations, "translation")) {
        return 1;
    }

    if (entries.size() != translations.size()) {
        std::cerr << "error: corpus and translation have different numbers of "
                     "entries\n";
        return 1;
    }

    for (std::size_t i{}; i < entries.size(); ++i) {
        if (entries[i].surah != translations[i].surah ||
            entries[i].ayah != translations[i].ayah) {
            std::cerr << "error: translation mismatch at entry " << i
                      << ": expected " << entries[i].surah << ':'
                      << entries[i].ayah << ", got " << translations[i].surah
                      << ':' << translations[i].ayah << '\n';
            return 1;
        }
    }

    std::string normalized_corpus;

    std::vector<Offset> offsets;
    offsets.reserve(entries.size());

    for (const auto& e : entries) {
        const auto normalized = safar::normalize_text(e.text);

        offsets.push_back({
            normalized_corpus.size(),
            normalized.size(),
        });

        normalized_corpus += normalized;
        normalized_corpus += ' ';
    }

    const auto header_path = output_dir / "corpus.hpp";
    const auto source_path = output_dir / "corpus.cpp";

    std::ofstream header(header_path);
    if (!header.is_open()) {
        std::cerr << "error: failed to write header file: " << header_path
                  << "\n";
        return 1;
    }

    header << "// AUTO-GENERATED FILE - DO NOT EDIT\n";
    header << "#pragma once\n\n";
    header << "#include <cstddef>\n";
    header << "#include <cstdint>\n";
    header << "#include <string_view>\n\n";
    header << "namespace safar {\n\n";
    header << "struct CorpusEntry {\n";
    header << "    std::string_view text;\n";
    header << "    std::string_view translation;\n";
    header << "    std::size_t norm_offset;\n";
    header << "    std::size_t norm_length;\n";
    header << "    std::uint16_t surah;\n";
    header << "    std::uint16_t ayah;\n";
    header << "};\n\n";
    header << "extern const CorpusEntry corpus[];\n";
    header << "extern const std::size_t corpus_size;\n\n";
    header << "extern const std::string_view normalized_corpus;\n\n";
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
    source << "#include <iterator>\n\n";
    source << "namespace {\n\n";
    source << "constexpr char normalized_corpus_data[] = \""
           << escape_cpp(normalized_corpus) << "\";\n\n";
    source << "}  // namespace\n\n";
    source << "namespace safar {\n\n";
    source << "const CorpusEntry corpus[] = {\n";

    for (std::size_t i{}; i < entries.size(); ++i) {
        const auto& e = entries[i];
        const auto& t = translations[i];
        const auto& offset = offsets[i];

        source << "    {\"" << escape_cpp(e.text) << "\", \""
               << escape_cpp(t.text) << "\", " << offset.offset << ", "
               << offset.length << ", " << e.surah << ", " << e.ayah << "},\n";
    }

    source << "};\n\n";
    source << "const std::size_t corpus_size{ std::size(corpus) };\n\n";
    source << "const std::string_view normalized_corpus{\n";
    source << "    normalized_corpus_data,\n";
    source << "    sizeof(normalized_corpus_data) - 1\n";
    source << "};\n\n";
    source << "}  // namespace safar";

    source.close();
}
