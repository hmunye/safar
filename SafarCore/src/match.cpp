#include "corpus.hpp"
#include "match.hpp"
#include "normalize.hpp"

#include <algorithm>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include <iostream>

namespace {

struct SubstringMatch {
    std::size_t distance;
    std::size_t start_offset;
    std::size_t end_offset;
};

struct MatchState {
    std::size_t distance;
    std::size_t start_offset;
};

// Computes the minimum Levenshtein distance between `x` and any substring of
// `y`, returning the edit distance and the range of the closest match.
//
// The allowed edits are:
//
//   - Insertion:    add one character
//   - Deletion:     remove one character
//   - Substitution: replace one character with another
//
// Unlike standard Levenshtein distance, this algorithm allows `x` to match
// against any position within `y`. The first row is initialized to zero,
// allowing unmatched prefixes of `y` to be skipped without cost. The returned
// offsets identify the matching substring in `y`.
SubstringMatch approx_substring_distance(std::string_view x,
                                         std::string_view y) {
    const std::size_t n{ x.size() };
    const std::size_t m{ y.size() };

    std::vector<MatchState> previous(m + 1);
    std::vector<MatchState> current(m + 1);

    // Allow matching `x` against any substring of `y`.
    for (std::size_t j{ 0 }; j <= m; ++j) {
        previous[j] = {
            .distance = 0,
            .start_offset = j,
        };
    }

    for (std::size_t i{ 1 }; i <= n; ++i) {
        current[0] = {
            .distance = i,
            .start_offset = 0,
        };

        for (std::size_t j{ 1 }; j <= m; ++j) {
            const auto cost = (x[i - 1] == y[j - 1]) ? 0 : 1;

            const MatchState deletion{
                previous[j].distance + 1,
                previous[j].start_offset,
            };

            const MatchState insertion{
                current[j - 1].distance + 1,
                current[j - 1].start_offset,
            };

            const MatchState substitution{
                previous[j - 1].distance + cost,
                previous[j - 1].start_offset,
            };

            current[j] = std::min({ deletion, insertion, substitution },
                                  [](const auto& a, const auto& b) {
                                      return a.distance < b.distance;
                                  });
        }

        std::swap(previous, current);
    }

    const auto it = std::min_element(
        previous.begin(), previous.end(),
        [](const auto& a, const auto& b) { return a.distance < b.distance; });

    const auto end_offset =
        static_cast<std::size_t>(std::distance(previous.begin(), it));

    return {
        .distance = it->distance,
        .start_offset = it->start_offset,
        .end_offset = end_offset,
    };
}

// Returns the index of the corpus entry containing the given character offset
// within the normalized corpus string, or `std::nullopt` if no entry contains
// the offset.
std::optional<std::size_t> find_verse_index(std::size_t normalized_offset) {
    for (std::size_t i{}; i < safar::corpus_size; ++i) {
        const auto& entry = safar::corpus[i];

        if (entry.norm_offset <= normalized_offset &&
            normalized_offset < entry.norm_offset + entry.norm_length) {
            return i;
        }
    }

    return std::nullopt;
}

}  // namespace

namespace safar {

std::vector<VerseMatch> match_transcription(const std::string& transcript) {
    std::vector<VerseMatch> verses;

    const auto normalized = normalize_text(transcript);
    std::cout << "transcript (normalized): " << normalized << "\n";

    const auto match =
        approx_substring_distance(normalized, safar::normalized_corpus);

    const auto idx = find_verse_index(match.start_offset);
    if (!idx) {
        return verses;
    }

    const auto start_idx = *idx;

    for (std::size_t i{ start_idx }; i < safar::corpus_size; ++i) {
        const auto& entry = safar::corpus[i];
        const auto end = entry.norm_offset + entry.norm_length;

        // Stop once this verse starts at or is beyond the end of the match. The
        // initial verse is still included on the first iteration.
        if (entry.norm_offset >= match.end_offset && i != start_idx) {
            break;
        }

        verses.push_back({
            entry.surah,
            entry.ayah,
            entry.text,
        });

        // Stop once this verse reaches the end of the matched region.
        if (end >= match.end_offset) {
            break;
        }
    }

    return verses;
}

}  // namespace safar
