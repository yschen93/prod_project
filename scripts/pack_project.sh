#!/usr/bin/env bash
set -euo pipefail

project_name="prod_project_delivery"

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${scripts_dir}/.." && pwd)"

build_root="${repo_root}/build"
dist_dir="${repo_root}/dist"
stage_dir="${dist_dir}/${project_name}"
tar_name="${project_name}.tar.gz"
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
# Instead of blindly copying from _deps, we use ldd to find actual runtime dependencies
# and copy them to stage/lib. This ensures we get exactly what the binaries need.

mkdir -p "${stage_dir}/lib"

# Helper to copy dependencies
CopyDependencies() {
  local binary="$1"
  local dest_lib_dir="$2"
  
  echo "Resolving dependencies for ${binary}..."
  
  # Use ldd to find dependencies, filter out system libs (libc, libstdc++, etc.)
  # We assume system libs are available on target machine.
  # Adjust the grep filter if you need to bundle libstdc++ or others.
  
  # CRITICAL FIX: The binary in stage/bin has RPATH set to $ORIGIN/../lib, which is empty right now.
  # So ldd on stage binary will fail to find libs.
  # We must run ldd on the ORIGINAL binary in build directory which has correct build RPATH.
  
  local bin_name=$(basename "${binary}")
  local build_bin=$(find "${build_root}" -name "${bin_name}" -type f -executable | head -n 1)
  
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
    
    if [[ "${lib_path}" == *"${build_root}"* ]]; then
      echo "  Bundling: ${lib_name}"
      cp -L "${lib_path}" "${dest_lib_dir}/"
    fi
  done
}

echo "Copying runtime libraries..."
# Find all executables in stage/bin and resolve their dependencies
find "${stage_dir}/bin" -type f -executable | while read -r bin; do
  CopyDependencies "${bin}" "${stage_dir}/lib"
done

# 3. Copy Config Files
# The binary expects "config/server.yaml" relative to CWD.
# CMake installs config to "share/integrated_demo/config".
# To make it work out-of-the-box when running from bin directory (or via wrapper),
# we copy config directory to bin/config.

if [[ -d "${stage_dir}/share/integrated_demo/config" ]]; then
  echo "Copying config files..."
  # Copy to bin/config (for running inside bin/)
  cp -r "${stage_dir}/share/integrated_demo/config" "${stage_dir}/bin/"
  # Copy to root/config (for running from root via ./bin/xxx)
  cp -r "${stage_dir}/share/integrated_demo/config" "${stage_dir}/"
fi

# 4. Create Start Scripts (Optional but recommended)
# Create a wrapper script to set LD_LIBRARY_PATH if RPATH fails or for safety
# cat <<EOF > "${stage_dir}/run.sh"
# #!/bin/bash
# DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
# export LD_LIBRARY_PATH="\${DIR}/lib:\${LD_LIBRARY_PATH}"
# exec "\${DIR}/bin/integrated_demo_server" "\$@"
# EOF
# chmod +x "${stage_dir}/run.sh"

# 4. Create Manifest
echo "Creating manifest..."
(cd "${stage_dir}" && find . \( -type f -o -type l \) | sort > manifest.txt)

# 5. Tarball
echo "Creating tarball: ${out_path}"
# Tar the directory with the project name
tar -czf "${out_path}" -C "${dist_dir}" "${project_name}"

# 6. Cleanup
echo "Cleaning up temporary files..."
rm -rf "${stage_dir}"

echo "Done. Package is at: ${out_path}"
