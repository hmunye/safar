#pragma once

#include "libsafar/libsafar.hpp"

#include <string>
#include <vector>

namespace safar {

// Matches transcription text against the Quran corpus, returning the identified
// verses.
[[nodiscard]] std::vector<VerseMatch> match_transcription(
    const std::string& transcript);

}  // namespace safar
