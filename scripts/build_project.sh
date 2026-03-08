#!/usr/bin/env bash
set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${scripts_dir}/.." && pwd)"

build_root="${BUILD_ROOT:-${repo_root}/build}"
install_prefix="${INSTALL_PREFIX:-${repo_root}/ins}"
build_type="${BUILD_TYPE:-Release}"

mkdir -p "${build_root}"

echo "Building project from root: ${repo_root}"
echo "Build dir: ${build_root}"
echo "Install prefix: ${install_prefix}"

# Configure
cmake -S "${repo_root}" -B "${build_root}" \
  -DCMAKE_BUILD_TYPE="${build_type}" \
  -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
  -DENABLE_CLANG_TIDY=OFF

# Build
cmake --build "${build_root}" --config "${build_type}" -j"$(nproc)"

# Test
ctest --test-dir "${build_root}" --output-on-failure

# Install (optional)
if [[ "${INSTALL:-0}" == "1" ]]; then
  cmake --install "${build_root}" --config "${build_type}"
fi
