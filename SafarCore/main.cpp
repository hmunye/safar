#include "libsafar/libsafar.hpp"

#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: " << argv[0] << " <model-path> <audio-path>\n";
        return 1;
    }

    const std::string model_path{ argv[1] };
    const std::string audio_path{ argv[2] };

    try {
        safar::RecitationIdentifier ri{ model_path };

        auto verses = ri.identify_verses(audio_path);

        for (const auto& v : verses) {
            std::cout << v.text;
        }
    } catch (const safar::IdentifierError& e) {
        std::cerr << e.what() << "\n";
        return 1;
    }

    std::cout << "\n";
}
