#include "normalize.hpp"

#include <optional>
#include <string>

namespace {

// Decodes the next UTF-8 encoded code-point from `input` starting at `index`.
//
// UTF-8 encodes each Unicode code-point using one to four bytes. The leading
// byte identifies the number of bytes in the sequence and contains the most
// significant bits of the code-point:
//
//   - 0xxxxxxx:                            1 byte (ASCII)
//   - 110xxxxx 10xxxxxx:                   2 bytes
//   - 1110xxxx 10xxxxxx 10xxxxxx:          3 bytes
//   - 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx: 4 bytes
//
// Bytes after the leading byte are continuation bytes, identified by the
// `10xxxxxx` prefix. This prefix marks them as part of the current code-point
// rather than the start of a new one. The remaining bits in each byte contain
// the code-point data. This function removes the UTF-8 markers, combines the
// data bits from each byte, and reconstructs the Unicode code-point.
char32_t decode_utf8_codepoint(const std::string& input, std::size_t& index) {
    const auto c = static_cast<unsigned char>(input[index]);

    // 0xxxxxxx: single-byte UTF-8 character (ASCII)
    if (c < 0x80) {
        index += 1;
        return c;
    }

    // 110xxxxx 10xxxxxx: two-byte UTF-8 character.
    if ((c & 0xE0) == 0xC0) {
        char32_t result = ((c & 0x1F) << 6) |
                          (static_cast<unsigned char>(input[index + 1]) & 0x3F);

        index += 2;
        return result;
    }

    // 1110xxxx 10xxxxxx 10xxxxxx: three-byte UTF-8 character.
    if ((c & 0xF0) == 0xE0) {
        char32_t result =
            ((c & 0x0F) << 12) |
            ((static_cast<unsigned char>(input[index + 1]) & 0x3F) << 6) |
            (static_cast<unsigned char>(input[index + 2]) & 0x3F);

        index += 3;
        return result;
    }

    // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx: four-byte UTF-8 character.
    char32_t result =
        ((c & 0x07) << 18) |
        ((static_cast<unsigned char>(input[index + 1]) & 0x3F) << 12) |
        ((static_cast<unsigned char>(input[index + 2]) & 0x3F) << 6) |
        (static_cast<unsigned char>(input[index + 3]) & 0x3F);

    index += 4;
    return result;
}

// Encodes a Unicode code-point into its UTF-8 byte sequence, appending the
// resulting bytes to `output`.
//
// The code-point is split into groups of payload bits, then combined with the
// appropriate UTF-8 markers to form the leading byte and any continuation
// bytes. The number of bytes appended depends on the size of the code-point.
void append_utf8_codepoint(std::string& output, char32_t codepoint) {
    // Fits in a single-byte UTF-8 sequence (7 payload bits, excluding markers).
    if (codepoint <= 0x7F) {
        output.push_back(static_cast<char>(codepoint));
    }

    // Fits in a two-byte UTF-8 sequence (11 payload bits, excluding markers).
    else if (codepoint <= 0x7FF) {
        output.push_back(static_cast<char>(0xC0 | (codepoint >> 6)));
        output.push_back(static_cast<char>(0x80 | (codepoint & 0x3F)));
    }

    // Fits in a three-byte UTF-8 sequence (16 payload bits, excluding markers).
    else if (codepoint <= 0xFFFF) {
        output.push_back(static_cast<char>(0xE0 | (codepoint >> 12)));
        output.push_back(static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F)));
        output.push_back(static_cast<char>(0x80 | (codepoint & 0x3F)));
    }

    // Fits in a four-byte UTF-8 sequence (21 payload bits, excluding markers).
    else {
        output.push_back(static_cast<char>(0xF0 | (codepoint >> 18)));
        output.push_back(static_cast<char>(0x80 | ((codepoint >> 12) & 0x3F)));
        output.push_back(static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F)));
        output.push_back(static_cast<char>(0x80 | (codepoint & 0x3F)));
    }
}

// https://tanzil.net/docs/uthmani_minimal
std::optional<char32_t> normalize_arabic_codepoint(char32_t codepoint) {
    switch (codepoint) {
        case U'\u064B':  // ARABIC FATHATAN (U+064B)
            [[fallthrough]];
        case U'\u064C':  // ARABIC DAMMATAN (U+064C)
            [[fallthrough]];
        case U'\u064D':  // ARABIC KASRATAN (U+064D)
            [[fallthrough]];

        case U'\u064E':  // ARABIC FATHA (U+064E)
            [[fallthrough]];
        case U'\u064F':  // ARABIC DAMMA (U+064F)
            [[fallthrough]];
        case U'\u0650':  // ARABIC KASRA (U+0650)
            [[fallthrough]];

        case U'\u0651':  // ARABIC SHADDA (U+0651)
            [[fallthrough]];
        case U'\u0652':  // ARABIC SUKUN (U+0652)
            [[fallthrough]];

        case U'\u0653':  // ARABIC MADDAH ABOVE (U+0653)
            [[fallthrough]];
        case U'\u06E2':  // ARABIC SMALL HIGH MEEM ISOLATED FORM (U+06E2)
            [[fallthrough]];
        case U'\u06E5':  // ARABIC SMALL WAW (U+06E5)
            [[fallthrough]];
        case U'\u06E6':  // ARABIC SMALL YEH (U+06E6)
            return std::nullopt;

        case U'\u0671':        // ARABIC LETTER ALEF WASLA (U+0671)
            return U'\u0627';  // ARABIC LETTER ALEF (U+0627)

        default:
            return codepoint;
    }
}

}  // namespace

namespace safar {

std::string normalize_text(const std::string& input) {
    std::string output;
    output.reserve(input.size());

    std::size_t index{};
    while (index < input.size()) {
        auto codepoint = decode_utf8_codepoint(input, index);

        auto normalized = normalize_arabic_codepoint(codepoint);
        if (normalized) {
            append_utf8_codepoint(output, *normalized);
        }
    }

    return output;
}

}  // namespace safar
