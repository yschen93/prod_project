#!/usr/bin/env bash
set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${scripts_dir}/.." && pwd)"

build_root="${repo_root}/build"
dist_dir="${repo_root}/dist"
stage_dir="${dist_dir}/stage"
tar_name="prod_project_delivery.tar.gz"
out_path="${dist_dir}/${tar_name}"

echo "Packing project..."
echo "Root: ${repo_root}"
echo "Dist dir: ${dist_dir}"
echo "Stage dir: ${stage_dir}"

# Clean previous stage/dist
rm -rf "${stage_dir}"
mkdir -p "${stage_dir}" "${dist_dir}"

# 1. Install project to stage directory
# We use the build script with INSTALL=1 and INSTALL_PREFIX
# Note: build_project.sh uses CMAKE_INSTALL_PREFIX
export INSTALL=1
export INSTALL_PREFIX="${stage_dir}"
export BUILD_ROOT="${build_root}"

# Ensure project is built and installed
"${scripts_dir}/build_project.sh"

# 2. Copy Runtime Libraries (Third Party)
# With FetchContent, shared libraries are typically built in build/_deps/<pkg>-build/
# We need to find and copy them to stage/lib.
# Also need to handle RPATH or LD_LIBRARY_PATH for the final package, 
# but for now we just copy the .so files next to binaries or in lib/

mkdir -p "${stage_dir}/lib"

# Helper to copy shared libs from build tree
CopyBuildSharedLibs() {
  local search_dir="$1"
  find "${search_dir}" -name "lib*.so*" -type f -exec cp -a {} "${stage_dir}/lib/" \;
  # Also copy symlinks if any (FetchContent build usually produces real files or symlinks)
  find "${search_dir}" -name "lib*.so*" -type l -exec cp -a {} "${stage_dir}/lib/" \;
}

echo "Copying runtime libraries..."
# Search in build/_deps for shared libraries
if [[ -d "${build_root}/_deps" ]]; then
    CopyBuildSharedLibs "${build_root}/_deps"
fi

# Clean up lib directory (remove cmake files, pkgconfig, etc if mistakenly copied, though find above is specific to .so)

# 3. Create Manifest
echo "Creating manifest..."
(cd "${stage_dir}" && find . \( -type f -o -type l \) | sort > manifest.txt)

# 4. Tarball
echo "Creating tarball: ${out_path}"
tar -czf "${out_path}" -C "${dist_dir}" stage

echo "Done. Package is at: ${out_path}"
