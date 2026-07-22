#!/usr/bin/env bash

set -euo pipefail
# set -x

if ! command -v git >/dev/null 2>&1; then
    printf "\033[0;31merror: git is required\033[0m\n" 1>&2
    exit 1
fi

if ! command -v git-lfs >/dev/null 2>&1; then
    printf "\033[0;31merror: git-lfs is required\033[0m\n" 1>&2
    printf "Git LFS manages large files associated with Git repositories.\n" 1>&2
    printf "Install it with a package manager (e.g., Homebrew):\n" 1>&2
    printf "\n" 1>&2
    printf "  brew install git-lfs\n" 1>&2
    printf "  git lfs install\n" 1>&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    printf "\033[0;31merror: python3 is required\033[0m\n" 1>&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WHISPER_VENDOR_DIR="${SCRIPT_DIR}/Sources/SafarCore/vendor/whisper.cpp"

HF_REPO="https://huggingface.co/tarteel-ai/whisper-base-ar-quran"
OPENAI_WHISPER_REPO="https://github.com/openai/whisper.git"

MODEL_NAME="whisper-base-ar-quran-ggml.bin"
MODEL_OUTPUT="${SCRIPT_DIR}/Safar/Resources/Models/${MODEL_NAME}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

printf "\033[0;34m==> using tmp directory: ${TMP_DIR}\033[0m\n" 1>&2

MODEL_DIR="${TMP_DIR}/whisper-base-ar-quran"
OPENAI_WHISPER_DIR="${TMP_DIR}/whisper"
VENV_DIR="${TMP_DIR}/venv"

printf "\033[0;34m==> cloning tarteel-ai/whisper-base-ar-quran...\033[0m\n" 1>&2
git clone --depth 1 "${HF_REPO}" "${MODEL_DIR}"

printf "\033[0;34m==> cloning openai/whisper.git...\033[0m\n" 1>&2
git clone --depth 1 "${OPENAI_WHISPER_REPO}" "${OPENAI_WHISPER_DIR}"

printf "\033[0;34m==> creating python venv...\033[0m\n" 1>&2
python3 -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"

printf "\033[0;34m==> installing conversion dependencies...\033[0m\n" 1>&2
"${VENV_DIR}/bin/python" -m pip install --quiet --upgrade pip
"${VENV_DIR}/bin/python" -m pip install --quiet transformers numpy torch

printf "\033[0;34m==> converting model...\033[0m\n" 1>&2
"${VENV_DIR}/bin/python" "${WHISPER_VENDOR_DIR}/models/convert-h5-to-ggml.py" \
    "${MODEL_DIR}" \
    "${OPENAI_WHISPER_DIR}" \
    "${TMP_DIR}"

if [[ ! -f "${TMP_DIR}/ggml-model.bin" ]]; then
    printf "\033[0;31merror: conversion failed: ggml-model.bin not found\033[0m\n" 1>&2
    exit 1
fi

mkdir -p "$(dirname "${MODEL_OUTPUT}")"
mv "${TMP_DIR}/ggml-model.bin" "${MODEL_OUTPUT}"

printf "\033[0;32m==> model ready: ${MODEL_OUTPUT}\033[0m\n" 1>&2
