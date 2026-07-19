#pragma once

#include <string>
#include <string_view>

namespace safar {

// Returns a normalized form of UTF-8 encoded Arabic text with collapsed
// whitespace and removed diacritics, tatweel, and Quranic marks.
[[nodiscard]] std::string normalize_text(std::string_view input);

}  // namespace safar
