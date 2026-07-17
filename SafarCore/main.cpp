#include "libsafar/libsafar.hpp"

#include <iostream>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: " << argv[0] << " <model-path> <audio-path>\n";
        return 1;
    }

    const std::string model_path = argv[1];
    const std::string audio_path = argv[2];

    try {
        safar::Transcriber t{ model_path };
        safar::Transcript ts = t.transcribe(audio_path);

        std::cout << "\n";

        for (const auto& seg : ts.segments) {
            std::cout << seg.text;
        }

        std::cout << "\n";
    } catch (const safar::Error& e) {
        std::cerr << e.what() << std::endl;
        return -1;
    }
}
