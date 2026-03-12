#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Packages the project for distribution.
#   Builds the project, copies runtime dependencies, and creates a tarball.
#

set -euo pipefail

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_NAME="prod_project_delivery"
readonly BUILD_ROOT="${REPO_ROOT}/build"
readonly DIST_DIR="${REPO_ROOT}/dist"
readonly STAGE_DIR="${DIST_DIR}/${PROJECT_NAME}"
readonly TAR_NAME="${PROJECT_NAME}.tar.gz"
readonly OUT_PATH="${DIST_DIR}/${TAR_NAME}"

# --- Helper Functions ---

copy_dependencies() {
  local binary="$1"
  local dest_lib_dir="$2"
  
  echo "Resolving dependencies for ${binary}..."
  
  # Use ldd to find dependencies, filter out system libs (libc, libstdc++, etc.)
  # We assume system libs are available on target machine.
  
  # CRITICAL FIX: The binary in stage/bin has RPATH set to $ORIGIN/../lib, which is empty right now.
  # So ldd on stage binary will fail to find libs.
  # We must run ldd on the ORIGINAL binary in build directory which has correct build RPATH.
  
  local bin_name=$(basename "${binary}")
  local build_bin=$(find "${BUILD_ROOT}" -name "${bin_name}" -type f -executable | head -n 1)
  
  if [[ -z "${build_bin}" ]]; then
    echo "Warning: Could not find build binary for ${bin_name}, skipping dependency check."
    return
  fi
  
  echo "  Using build binary: ${build_bin}"
  
  ldd "${build_bin}" | awk '{print $3}' | grep -v "^(" | grep -v "^$" | while read -r lib_path; do
    local lib_name=$(basename "${lib_path}")
    
    # Skip system libraries (usually in /lib, /usr/lib, etc.)
    # We only want to bundle libraries that are part of our build (e.g. from _deps)
    # or custom locations.
    # A simple heuristic: if it comes from our build directory, copy it.
    
    if [[ "${lib_path}" == *"${BUILD_ROOT}"* ]]; then
      echo "  Bundling: ${lib_name}"
      cp -L "${lib_path}" "${dest_lib_dir}/"
    fi
  done
}

# --- Main Execution ---

echo "Packing project..."
echo "Root: ${REPO_ROOT}"
echo "Dist dir: ${DIST_DIR}"
echo "Stage dir: ${STAGE_DIR}"

# Clean previous stage/dist
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}" "${DIST_DIR}"

# 1. Install project to stage directory
# We use the build script with INSTALL=1 and INSTALL_PREFIX
# Note: build_project.sh uses CMAKE_INSTALL_PREFIX
export INSTALL=1
export INSTALL_PREFIX="${STAGE_DIR}"
export BUILD_ROOT="${BUILD_ROOT}"

# Ensure project is built and installed
"${SCRIPT_DIR}/build_project.sh"

# 2. Copy Runtime Libraries (Third Party)
# Instead of blindly copying from _deps, we use ldd to find actual runtime dependencies
# and copy them to stage/lib. This ensures we get exactly what the binaries need.

mkdir -p "${STAGE_DIR}/lib"

echo "Copying runtime libraries..."
# Find all executables in stage/bin and resolve their dependencies
find "${STAGE_DIR}/bin" -type f -executable | while read -r bin; do
  copy_dependencies "${bin}" "${STAGE_DIR}/lib"
done

# 3. Copy Config Files
# The binary expects "config/server.yaml" relative to CWD.
# CMake installs config to "share/integrated_demo/config".
# To make it work out-of-the-box when running from bin directory (or via wrapper),
# we copy config directory to bin/config.

if [[ -d "${STAGE_DIR}/share/integrated_demo/config" ]]; then
  echo "Copying config files..."
  # Copy to bin/config (for running inside bin/)
  cp -r "${STAGE_DIR}/share/integrated_demo/config" "${STAGE_DIR}/bin/"
  # Copy to root/config (for running from root via ./bin/xxx)
  cp -r "${STAGE_DIR}/share/integrated_demo/config" "${STAGE_DIR}/"
fi

# 4. Create Manifest
echo "Creating manifest..."
(cd "${STAGE_DIR}" && find . \( -type f -o -type l \) | sort > manifest.txt)

# 5. Tarball
echo "Creating tarball: ${OUT_PATH}"
# Tar the directory with the project name
tar -czf "${OUT_PATH}" -C "${DIST_DIR}" "${PROJECT_NAME}"

# 6. Cleanup
echo "Cleaning up temporary files..."
rm -rf "${STAGE_DIR}"

echo "Done. Package is at: ${OUT_PATH}"
