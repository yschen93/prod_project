#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Builds the project using CMake.
#   Supports debug/release builds and installation.
#

set -euo pipefail

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Main Execution ---

build_root="${BUILD_ROOT:-${REPO_ROOT}/build}"
install_prefix="${INSTALL_PREFIX:-${REPO_ROOT}/ins}"
build_type="${BUILD_TYPE:-Release}"

mkdir -p "${build_root}"

echo "Building project from root: ${REPO_ROOT}"
echo "Build dir: ${build_root}"
echo "Install prefix: ${install_prefix}"

# Configure
cmake -S "${REPO_ROOT}" -B "${build_root}" \
  -DCMAKE_BUILD_TYPE="${build_type}" \
  -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DENABLE_CLANG_TIDY=OFF

# Build
cmake --build "${build_root}" --config "${build_type}" -j"$(nproc)"

# Test
ctest --test-dir "${build_root}" --output-on-failure

# Install (optional)
if [[ "${INSTALL:-0}" == "1" ]]; then
  cmake --install "${build_root}" --config "${build_type}"
fi
