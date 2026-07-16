#pragma once

#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace safar {

class Error : public std::runtime_error {
   public:
    using std::runtime_error::runtime_error;
};

// Single segment of recognized text and associated metadata.
struct Segment {
    std::string text;
};

// Recognized text produced from a recitation audio input.
struct Transcript {
    std::vector<Segment> segments;
};

// Transcribes recitation audio into text segments.
class Transcriber {
    struct Impl;
    std::unique_ptr<Impl> impl_;

   public:
    explicit Transcriber(const std::string& model_path);
    ~Transcriber();

    Transcriber(Transcriber&&) noexcept;
    Transcriber& operator=(Transcriber&&) noexcept;

    Transcriber(const Transcriber&) = delete;
    Transcriber& operator=(const Transcriber&) = delete;

    Transcript transcribe(const std::string& audio_path);
};

}  // namespace safar
