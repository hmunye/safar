#include "libsafar/libsafar.hpp"
#include "model.hpp"

#include <cstdint>
#include <algorithm>
#include <fstream>
#include <string>
#include <vector>

namespace {

// Loads a 16-bit PCM WAV file and converts samples to normalized float values.
//
// Throws `safar::IdentifierError` if processing fails.
std::vector<float> load_wav(const std::string& audio_path) {
    std::ifstream file(audio_path, std::ios::binary);
    if (!file) {
        throw safar::IdentifierError("failed to open audio file: " +
                                     audio_path);
    }

    file.seekg(0, std::ios::end);

    const auto file_size{ file.tellg() };
    if (file_size < 44) {
        throw safar::IdentifierError(
            "failed to process audio file; invalid WAV header: " + audio_path);
    }

    // Skip the 44-byte WAV header (start of PCM sample data).
    file.seekg(44, std::ios::beg);

    std::vector<float> pcmf32;
    pcmf32.reserve((static_cast<std::size_t>(file_size) - 44) /
                   sizeof(int16_t));

    std::int16_t sample;
    while (file.read(reinterpret_cast<char*>(&sample), sizeof(sample))) {
        const auto normalized{ std::clamp(static_cast<float>(sample) / 32768.0f,
                                          -1.0f, 1.0f) };
        pcmf32.push_back(normalized);
    }

    if (!file.eof()) {
        throw safar::IdentifierError(
            "failed to process audio file; failed to read samples: " +
            audio_path);
    }

    return pcmf32;
}

}  // namespace

namespace safar {

Model::Model(const std::string& model_path)
    : wparams(whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH)) {
    whisper_context_params cparams{ whisper_context_default_params() };

    ctx = whisper_init_from_file_with_params(model_path.c_str(), cparams);
    if (!ctx) {
        throw IdentifierError("failed to load model: " + model_path);
    }

    wparams.translate = false;

    wparams.language = "ar";
    wparams.detect_language = false;
}

Model::~Model() {
    if (ctx) {
        whisper_free(ctx);
    }
}

Model::Model(Model&& other) noexcept : ctx(other.ctx), wparams(other.wparams) {
    other.ctx = nullptr;
}

Model& Model::operator=(Model&& other) noexcept {
    if (this != &other) {
        if (ctx) {
            whisper_free(ctx);
        }

        ctx = other.ctx;
        wparams = other.wparams;

        other.ctx = nullptr;
    }

    return *this;
}

std::string Model::transcribe(const std::string& audio_path) {
    auto pcmf32 = load_wav(audio_path);

    if (whisper_full(ctx, wparams, pcmf32.data(),
                     static_cast<int>(pcmf32.size())) != 0) {
        throw IdentifierError("failed to run model");
    }

    const int n_segments{ whisper_full_n_segments(ctx) };

    std::string transcript;
    for (int i{ 0 }; i < n_segments; ++i) {
        transcript += whisper_full_get_segment_text(ctx, i);
    }

    return transcript;
}

}  // namespace safar
