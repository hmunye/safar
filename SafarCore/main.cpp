#include "libsafar/libsafar.hpp"

#include <iomanip>
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

        const auto verses = ri.identify_verses(audio_path);

        if (verses.empty()) {
            std::cout << "no matches found" << "\n";
        } else {
            for (const auto& v : verses) {
                std::cout << std::fixed << std::setprecision(2) << "match "
                          << v.surah << ":" << v.ayah << " (" << v.confidence
                          << " confidence) - matched text: " << v.text << "\n";
            }
        }
    } catch (const safar::IdentifierError& e) {
        std::cerr << e.what() << "\n";
        return 1;
    }
}
