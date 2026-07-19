#pragma once

#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace safar {

// Exception thrown when the identification pipeline fails.
class IdentifierError : public std::runtime_error {
   public:
    using std::runtime_error::runtime_error;
};

// Verse identified from a recitation audio clip and associated metadata.
struct VerseMatch {
    std::string text;
};

// Identifies Quran verses contained in a recitation audio clip.
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

    // Identifies verses contained in the provided recitation audio clip.
    //
    // Throws `safar::IdentifierError` if processing fails.
    [[nodiscard]] std::vector<VerseMatch> identify_verses(
        const std::string& audio_path);
};

}  // namespace safar
