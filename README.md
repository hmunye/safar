# safar

An iOS application for capturing Quran recitation clips on-device, with offline
processing to identify verse ranges from audio, played back in a scrollable feed.

## Setup

### Model

This project uses [`tarteel-ai/whisper-base-ar-quran`](https://huggingface.co/tarteel-ai/whisper-base-ar-quran),
converted for use with [`ggml-org/whisper.cpp`](https://github.com/ggml-org/whisper.cpp).

To prepare the model, run:

```bash
./prepare_model.sh
```

## License

This project is licensed under the [MIT License].

[MIT License]: https://github.com/hmunye/safar/blob/main/LICENSE

## References

- [Tanzil](https://tanzil.net/docs/)
