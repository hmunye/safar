#pragma once

#include <cstdint>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace safar {

// Exception thrown when the identification pipeline fails.
class IdentifierError : public std::runtime_error {
   public:
    using std::runtime_error::runtime_error;
};

// Verse identified from a recitation audio clip and associated metadata.
struct VerseMatch {
    std::string_view text;
    // Confidence score indicating how strongly this verse matches the
    // identified recitation segment, in the range [0.0, 1.0].
    float confidence;
    std::uint16_t surah;
    std::uint16_t ayah;
};

// Identifies Quran verses recited in an audio clip.
class RecitationIdentifier {
    struct Impl;
    std::unique_ptr<Impl> impl_;

   public:
    // Prepares the identification pipeline using the given ASR model.
    //
    // Throws `safar::IdentifierError` if the model cannot be loaded.
    explicit RecitationIdentifier(const std::string& model_path);
    ~RecitationIdentifier();

    RecitationIdentifier(RecitationIdentifier&&) noexcept;
    RecitationIdentifier& operator=(RecitationIdentifier&&) noexcept;

    RecitationIdentifier(const RecitationIdentifier&) = delete;
    RecitationIdentifier& operator=(const RecitationIdentifier&) = delete;

    // Identifies verses recited in an audio clip.
    //
    // Throws `safar::IdentifierError` if processing fails.
    [[nodiscard]] std::vector<VerseMatch> identify_verses(
        const std::string& audio_path);
};

}  // namespace safar
