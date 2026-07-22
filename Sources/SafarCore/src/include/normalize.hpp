#pragma once

#include <string>

namespace safar {

// Returns a normalized form of UTF-8 encoded Arabic text, removing
// non-essential pronunciation and annotation marks while preserving
// the underlying Arabic text.
[[nodiscard]] std::string normalize_text(const std::string& input);

}  // namespace safar
