#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${root_dir}/.." && pwd)"

build_root="${repo_root}/build"
build_root="${BUILD_ROOT:-${build_root}}"
install_prefix="${INSTALL_PREFIX:-${repo_root}/out}"
build_type="${BUILD_TYPE:-Release}"
prefix_path="${CMAKE_PREFIX_PATH:-}"
default_tp_prefix="${repo_root}/third_party/ins"

if [[ -z "${prefix_path}" && -d "${default_tp_prefix}" ]]; then
  prefix_path="${default_tp_prefix}"
fi

mkdir -p "${build_root}"

projects=()
while IFS= read -r -d '' f; do
  projects+=("$(dirname "${f}")")
done < <(find "${repo_root}/src" -mindepth 2 -maxdepth 2 -type f -name CMakeLists.txt -print0 2>/dev/null || true)

if [[ ${#projects[@]} -eq 0 ]]; then
  echo "No CMake projects found under ${repo_root}/src" >&2
  exit 2
fi

for proj in "${projects[@]}"; do
  name="$(basename "${proj}")"
  bld="${build_root}/${name}"

  args=(
    -S "${proj}"
    -B "${bld}"
    -DCMAKE_BUILD_TYPE="${build_type}"
    -DCMAKE_INSTALL_PREFIX="${install_prefix}"
  )
  if [[ -n "${prefix_path}" ]]; then
    args+=(-DCMAKE_PREFIX_PATH="${prefix_path}")
  fi

  cmake "${args[@]}"
  cmake --build "${bld}" --config "${build_type}" -j"$(nproc)"
  ctest --test-dir "${bld}" --output-on-failure

  if [[ "${INSTALL:-0}" == "1" ]]; then
    cmake --install "${bld}" --config "${build_type}"
  fi
done
