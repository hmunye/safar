#include <libsafar/libsafar.hpp>

#include <fstream>
#include <algorithm>

#include <whisper.h>

namespace {

// Loads a 16-bit PCM WAV file and converts samples to normalized float values.
std::vector<float> load_wav(const std::string& audio_path) {
    std::ifstream file(audio_path, std::ios::binary);
    if (!file) {
        throw safar::Error("failed to open WAV file");
    }

    file.seekg(0, std::ios::end);

    const auto file_size = file.tellg();
    if (file_size < 44) {
        throw safar::Error("failed to process WAV file: invalid WAV header");
    }

    // Move past the 44-byte WAV header to the start of the PCM sample data.
    file.seekg(44, std::ios::beg);

    std::vector<float> pcmf32;
    pcmf32.reserve((static_cast<std::size_t>(file_size) - 44) /
                   sizeof(int16_t));

    int16_t sample;
    while (file.read(reinterpret_cast<char*>(&sample), sizeof(sample))) {
        const auto normalized =
            std::clamp(static_cast<float>(sample) / 32768.0f, -1.0f, 1.0f);
        pcmf32.push_back(normalized);
    }

    if (!file.eof()) {
        throw safar::Error(
            "failed to process WAV file: failed to read samples");
    }

    return pcmf32;
}

}  // namespace

namespace safar {

struct Transcriber::Impl {
    whisper_context* ctx = nullptr;
    whisper_full_params wparams =
        whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH);

    ~Impl() {
        if (ctx) {
            whisper_free(ctx);
        }
    }
};

Transcriber::Transcriber(const std::string& model_path)
    : impl_(std::make_unique<Impl>()) {
    whisper_context_params cparams = whisper_context_default_params();

    impl_->ctx =
        whisper_init_from_file_with_params(model_path.c_str(), cparams);
    if (!impl_->ctx) {
        throw safar::Error("failed to load ASR model");
    }

    impl_->wparams.translate = false;

    impl_->wparams.language = "ar";
    impl_->wparams.detect_language = false;
}

Transcriber::~Transcriber() = default;

Transcriber::Transcriber(Transcriber&&) noexcept = default;
Transcriber& Transcriber::operator=(Transcriber&&) noexcept = default;

safar::Transcript Transcriber::transcribe(const std::string& audio_path) {
    std::vector<float> pcmf32 = load_wav(audio_path);

    if (whisper_full(impl_->ctx, impl_->wparams, pcmf32.data(),
                     static_cast<int>(pcmf32.size())) != 0) {
        throw safar::Error("failed to run ASR model");
    }

    const int n_segments = whisper_full_n_segments(impl_->ctx);

    std::vector<Segment> segments;
    segments.reserve(static_cast<std::size_t>(n_segments));

    for (int i = 0; i < n_segments; ++i) {
        segments.push_back(Segment{
            std::string(whisper_full_get_segment_text(impl_->ctx, i)),
        });
    }

    return { std::move(segments) };
}

}  // namespace safar
