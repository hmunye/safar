#include "libsafar/libsafar.hpp"
#include "match.hpp"
#include "model.hpp"

#include <memory>
#include <string>
#include <vector>

namespace safar {

struct RecitationIdentifier::Impl {
    Model model;

    explicit Impl(const std::string& model_path) : model(model_path) {
    }
};

RecitationIdentifier::RecitationIdentifier(const std::string& model_path)
    : impl_(std::make_unique<Impl>(model_path)) {
}

RecitationIdentifier::~RecitationIdentifier() = default;

RecitationIdentifier::RecitationIdentifier(RecitationIdentifier&&) noexcept =
    default;
RecitationIdentifier& RecitationIdentifier::operator=(
    RecitationIdentifier&&) noexcept = default;

std::vector<VerseMatch> RecitationIdentifier::identify_verses(
    const std::string& audio_path) const {
    const auto transcript = impl_->model.transcribe(audio_path);

    return match_transcription(transcript);
}

}  // namespace safar
