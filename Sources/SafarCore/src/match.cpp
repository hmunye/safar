#include "corpus.hpp"
#include "match.hpp"
#include "normalize.hpp"

#include <algorithm>
#include <limits>
#include <numeric>
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

// Computes the standard Levenshtein distance between two strings, returning the
// edit distance.
//
// The allowed edits are:
//
//   - Insertion:    add one character
//   - Deletion:     remove one character
//   - Substitution: replace one character with another
std::size_t levenshtein_distance(std::string_view x, std::string_view y) {
    const std::size_t n{ x.size() };
    const std::size_t m{ y.size() };

    std::vector<std::size_t> previous(m + 1);
    std::vector<std::size_t> current(m + 1);

    std::iota(previous.begin(), previous.end(), 0);

    for (std::size_t i{ 1 }; i <= n; ++i) {
        current[0] = i;

        for (std::size_t j{ 1 }; j <= m; ++j) {
            const auto cost = (x[i - 1] == y[j - 1]) ? 0 : 1;

            const auto deletion = previous[j] + 1;
            const auto insertion = current[j - 1] + 1;
            const auto substitution = previous[j - 1] + cost;

            current[j] = std::min({
                deletion,
                insertion,
                substitution,
            });
        }

        std::swap(previous, current);
    }

    return previous[m];
}

// Computes the Levenshtein distance between `x` and any substring of `y`,
// returning the edit distance and the range of the closest match.
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
SubstringMatch substring_levenshtein_distance(std::string_view x,
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

// Returns the normalized corpus offset where the spoken content of an entry
// begins for the given match region, based on heuristics.
std::size_t spoken_content_offset(const safar::CorpusEntry& entry,
                                  std::size_t start) {
    // First ayah entries include the basmalah, but the prefix is skipped only
    // when the matched region begins after it.
    constexpr std::size_t norm_basmalah_length = 45;

    if (entry.ayah != 1) {
        return entry.norm_offset;
    }

    const auto basmalah_end = entry.norm_offset + norm_basmalah_length;

    if (start < basmalah_end) {
        return entry.norm_offset;
    }

    // Account for whitespace after prefix.
    return basmalah_end + 1;
}

// Computes the edit distance between a prefix of the transcript and prefix of
// the normalized corpus starting at the given candidate offset.
std::size_t boundary_distance(std::string_view transcript,
                              std::size_t candidate_offset) {
    constexpr std::size_t prefix_length = 150;

    const auto transcript_prefix =
        transcript.substr(0, std::min(prefix_length, transcript.size()));

    const auto candidate_prefix = safar::normalized_corpus.substr(
        candidate_offset,
        std::min(prefix_length,
                 safar::normalized_corpus.size() - candidate_offset));

    return levenshtein_distance(transcript_prefix, candidate_prefix);
}

// Returns the best starting verse index near an initial approximate match,
// comparing nearby verse boundaries against the beginning of the transcript
// and selecting the candidate with the lowest edit distance.
std::size_t refine_verse_index(std::size_t initial_idx,
                               std::string_view transcript) {
    constexpr std::size_t candidate_count = 4;

    auto idx = initial_idx;
    auto min_dist = std::numeric_limits<std::size_t>::max();

    for (std::size_t i{ initial_idx };
         i < std::min(initial_idx + candidate_count, safar::corpus_size); ++i) {
        const auto dist = boundary_distance(
            transcript,
            spoken_content_offset(
                safar::corpus[i],
                safar::corpus[i].norm_offset + safar::corpus[i].norm_length));

        if (dist < min_dist) {
            min_dist = dist;
            idx = i;
        }
    }

    return idx;
}

// Computes confidence that a corpus entry corresponds to the matched transcript
// region. The returned score combines verse coverage with the approximate match
// quality.
float calculate_confidence(const safar::CorpusEntry& entry, std::size_t start,
                           std::size_t end, std::size_t distance) {
    constexpr float sim_base = 0.5f;    // Minimum similarity contribution.
    constexpr float sim_weight = 0.5f;  // Influence of similarity on score.

    const auto entry_start = spoken_content_offset(entry, start);
    const auto entry_end = entry.norm_offset + entry.norm_length;

    const auto overlap_start = std::max(entry_start, start);
    const auto overlap_end = std::min(entry_end, end);

    if (overlap_start >= overlap_end) {
        return 0.0f;
    }

    const float coverage = static_cast<float>(overlap_end - overlap_start) /
                           static_cast<float>(entry_end - entry_start);

    const auto matched_length = end - start;

    const float similarity =
        1.0f - static_cast<float>(distance) /
                   static_cast<float>(
                       std::max(matched_length, entry_end - entry_start));

    return coverage * (sim_base + sim_weight * similarity);
}

constexpr float min_confidence = 0.7f;

}  // namespace

namespace safar {

std::vector<VerseMatch> match_transcription(const std::string& transcript) {
    std::vector<VerseMatch> verses;

    const auto normalized = normalize_text(transcript);
    std::cout << "transcript (normalized): " << normalized << "\n";

    const auto match =
        substring_levenshtein_distance(normalized, safar::normalized_corpus);

    const auto idx = find_verse_index(match.start_offset);
    if (!idx) {
        return verses;
    }

    const auto start = refine_verse_index(*idx, normalized);

    for (std::size_t i{ start }; i < safar::corpus_size; ++i) {
        const auto& entry = safar::corpus[i];
        const auto end = entry.norm_offset + entry.norm_length;

        // Stop once this verse starts at or is beyond the end of the match. The
        // initial verse is still included on the first iteration.
        if (entry.norm_offset >= match.end_offset && i != start) {
            break;
        }

        const auto c = calculate_confidence(entry, match.start_offset,
                                            match.end_offset, match.distance);

        if (c >= min_confidence) {
            verses.push_back({
                .text = entry.text,
                .confidence = c,
                .surah = entry.surah,
                .ayah = entry.ayah,
            });
        }

        // Stop once this verse reaches the end of the matched region.
        if (end >= match.end_offset) {
            break;
        }
    }

    return verses;
}

}  // namespace safar
