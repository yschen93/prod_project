#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Downloads and builds LLVM tools (clang-format, clang-tidy) from source.
#   Installs them into the local tools/ directory.
#

set -euo pipefail

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly LLVM_WORK_DIR="${PROJECT_ROOT}/third_party/llvm"
readonly TOOLS_DIR="${PROJECT_ROOT}/tools"
readonly BUILD_DIR="${LLVM_WORK_DIR}/build"
readonly EXTRACT_DIR="${LLVM_WORK_DIR}/src"

# --- Main Execution ---

if [[ ! -d "${LLVM_WORK_DIR}" ]]; then
    echo "Error: LLVM work directory not found: ${LLVM_WORK_DIR}"
    echo "Please download LLVM source tarball and place it there."
    exit 1
fi

# Find LLVM tarball with wildcard pattern
# Sort by name (version) descending and pick the first one to prefer newer versions if multiple exist
LLVM_TARBALL=$(find "${LLVM_WORK_DIR}" -maxdepth 1 -name "llvm*.tar.gz" | sort -r | head -n 1)

# Pre-flight Checks
if [[ -z "${LLVM_TARBALL}" ]]; then
    echo "Error: No LLVM tarball (llvm*.tar.gz) found in ${LLVM_WORK_DIR}"
    exit 1
fi

echo "Project Root: ${PROJECT_ROOT}"
echo "Using LLVM tarball: ${LLVM_TARBALL}"
echo "Tools output directory: ${TOOLS_DIR}"
echo "LLVM work directory: ${LLVM_WORK_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Extraction directory: ${EXTRACT_DIR}"

# Preparation
mkdir -p "${TOOLS_DIR}"
mkdir -p "${LLVM_WORK_DIR}"

# Clean up old temporary directories if they exist
rm -rf "${BUILD_DIR}"
rm -rf "${EXTRACT_DIR}"

# Create new temporary directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${EXTRACT_DIR}"

# Extraction
echo "Extracting LLVM source..."
tar -xf "${LLVM_TARBALL}" -C "${EXTRACT_DIR}"

# Detect the source directory name (it might contain version numbers)
# We assume there's only one top-level directory in the tarball
LLVM_SRC_DIR=$(find "${EXTRACT_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [[ -z "${LLVM_SRC_DIR}" ]]; then
    echo "Error: Could not detect extracted directory in ${EXTRACT_DIR}"
    exit 1
fi

echo "Detected source directory: ${LLVM_SRC_DIR}"

# Build
# Enter build directory
cd "${BUILD_DIR}"

# Configure CMake
echo "Configuring CMake..."
cmake -G "Ninja" \
    -S "${LLVM_SRC_DIR}/llvm" \
    -B . \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLLVM_TARGETS_TO_BUILD="Native" \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DCMAKE_CXX_STANDARD=17 \
    -DCLANG_ENABLE_ARCMT=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
    -DBUILD_SHARED_LIBS=OFF

# Build clang-format and clang-tidy
echo "Building clang-format and clang-tidy..."
# Detect CPU count for parallel build
NPROC=$(nproc 2>/dev/null || echo 4)
echo "Building with ${NPROC} parallel jobs..."
cmake --build . --target clang-format clang-tidy -j"${NPROC}"

# Copy executables and resources
echo "Copying executables and resources to ${TOOLS_DIR}..."
mkdir -p "${TOOLS_DIR}/bin"
mkdir -p "${TOOLS_DIR}/lib"

cp "${BUILD_DIR}/bin/clang-format" "${TOOLS_DIR}/bin/"
cp "${BUILD_DIR}/bin/clang-tidy" "${TOOLS_DIR}/bin/"

# Copy clang internal headers (required for stdarg.h, stddef.h etc)
# Clang tools need these relative to the binary (../lib/clang/<version>/include)
# Search in BUILD_DIR/lib/clang and BUILD_DIR/lib64/clang
if [[ -d "${BUILD_DIR}/lib/clang" ]]; then
    echo "Copying clang internal headers (from lib/clang)..."
    cp -r "${BUILD_DIR}/lib/clang" "${TOOLS_DIR}/lib/"
elif [[ -d "${BUILD_DIR}/lib64/clang" ]]; then
    echo "Copying clang internal headers (from lib64/clang)..."
    cp -r "${BUILD_DIR}/lib64/clang" "${TOOLS_DIR}/lib/"
elif [[ -d "${BUILD_DIR}/lib" ]]; then
    # Fallback: copy entire lib directory if specific clang subdir not found
    echo "Copying library files (fallback)..."
    cp -r "${BUILD_DIR}/lib" "${TOOLS_DIR}/"
else
    echo "Error: Clang internal headers not found. Static analysis might fail due to missing stdarg.h."
    exit 1
fi

# Verification & Cleanup
if [[ -f "${TOOLS_DIR}/bin/clang-format" ]] && [[ -f "${TOOLS_DIR}/bin/clang-tidy" ]]; then
    echo "Success! Tools installed in ${TOOLS_DIR}"
    ls -l "${TOOLS_DIR}/bin"
    if [[ -d "${TOOLS_DIR}/lib/clang" ]]; then
        echo "Clang headers installed:"
        ls -d "${TOOLS_DIR}/lib/clang"/*
    fi

    # Cleanup
    echo "Cleaning up temporary directories..."
    cd "${PROJECT_ROOT}" # Leave build dir to allow deletion
    rm -rf "${LLVM_WORK_DIR}"
    echo "Cleanup complete."
else
    echo "Error: Tools were not copied correctly."
    exit 1
fi
