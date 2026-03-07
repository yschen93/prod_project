#!/usr/bin/env bash
set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${scripts_dir}/.." && pwd)"

BUILD_DIR="${repo_root}/build"

echo "Configuring project with clang-tidy enabled..."
# Remove cache to ensure paths are updated if tools were moved or uninstalled
if [ -f "${BUILD_DIR}/CMakeCache.txt" ]; then
    echo "Clearing CMake cache..."
    rm "${BUILD_DIR}/CMakeCache.txt"
fi
cmake -S "${repo_root}" -B "${BUILD_DIR}" -DENABLE_CLANG_TIDY=ON

echo "Running static analysis (forcing full check)..."
# Clean to ensure all files are re-compiled and re-checked
cmake --build "${BUILD_DIR}" --target clean
cmake --build "${BUILD_DIR}" -j$(nproc)
