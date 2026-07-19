#pragma once

#include <whisper.h>

#include <string>

namespace safar {

class Model {
    whisper_context* ctx = nullptr;
    whisper_full_params wparams;

   public:
    // Initializes the Whisper context and parameters with the provided ASR
    // model.
    //
    // Throws `safar::IdentifierError` if the model cannot be loaded.
    explicit Model(const std::string& model_path);
    ~Model();

    Model(Model&&) noexcept;
    Model& operator=(Model&&) noexcept;

    Model(const Model&) = delete;
    Model& operator=(const Model&) = delete;

    // Transcribes the provided recitation audio clip.
    //
    // Throws `safar::IdentifierError` if transcription fails.
    [[nodiscard]] std::string transcribe(const std::string& audio_path);
};

}  // namespace safar
