#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${root_dir}/../.." && pwd)"
work_root="${repo_root}/../3rd"
tarballs_dir="${repo_root}/third_party/tarballs"

prefix_dir="${repo_root}/third_party/ins"
src_dir="${work_root}/src"
build_dir="${work_root}/build"

cmake_bin="cmake"
nproc_bin="nproc"

rm -rf "${prefix_dir}"
mkdir -p "${prefix_dir}" "${src_dir}" "${build_dir}"

ExtractTarball() {
  local tar_path="$1"
  local dest_dir="$2"
  local strip_components="$3"

  rm -rf "${dest_dir}"
  mkdir -p "${dest_dir}"
  tar -xzf "${tar_path}" -C "${dest_dir}" --strip-components="${strip_components}"
}

ConfigureBuildInstall() {
  local name="$1"
  local src="$2"
  local bld="$3"
  shift 3

  rm -rf "${bld}"
  "${cmake_bin}" -S "${src}" -B "${bld}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${prefix_dir}" "$@"
  "${cmake_bin}" --build "${bld}" --config Release -j"$(${nproc_bin})"
  "${cmake_bin}" --install "${bld}" --config Release

  if [[ -f "${bld}/install_manifest.txt" ]]; then
    cp -f "${bld}/install_manifest.txt" "${bld}/install_manifest.${name}.txt"
  fi
}

ConfigureInstallOnly() {
  local name="$1"
  local src="$2"
  local bld="$3"
  shift 3

  rm -rf "${bld}"
  "${cmake_bin}" -S "${src}" -B "${bld}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${prefix_dir}" "$@"
  "${cmake_bin}" --install "${bld}" --config Release

  if [[ -f "${bld}/install_manifest.txt" ]]; then
    cp -f "${bld}/install_manifest.txt" "${bld}/install_manifest.${name}.txt"
  fi
}

ConfigureBuildAndTest() {
  local name="$1"
  local src="$2"
  local bld="$3"
  shift 3

  rm -rf "${bld}"
  "${cmake_bin}" -S "${src}" -B "${bld}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix_dir}" \
    -DCMAKE_INSTALL_PREFIX="${prefix_dir}" \
    "$@"
  "${cmake_bin}" --build "${bld}" --config Release -j"$(${nproc_bin})"
  ctest --test-dir "${bld}" --output-on-failure
}

ConfigureBuildTestInstall() {
  local name="$1"
  local src="$2"
  local bld="$3"
  shift 3

  rm -rf "${bld}"
  "${cmake_bin}" -S "${src}" -B "${bld}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix_dir}" \
    -DCMAKE_INSTALL_PREFIX="${prefix_dir}" \
    "$@"
  "${cmake_bin}" --build "${bld}" --config Release -j"$(${nproc_bin})"
  ctest --test-dir "${bld}" --output-on-failure
  "${cmake_bin}" --install "${bld}" --config Release

  if [[ -f "${bld}/install_manifest.txt" ]]; then
    cp -f "${bld}/install_manifest.txt" "${bld}/install_manifest.${name}.txt"
  fi
}

PruneDuplicatedShareCmake() {
  local share_cmake_dir="${prefix_dir}/share/cmake"
  local lib_cmake_dir="${prefix_dir}/lib/cmake"

  if [[ ! -d "${share_cmake_dir}" ]]; then
    return
  fi
  if [[ ! -d "${lib_cmake_dir}" ]]; then
    return
  fi

  while IFS= read -r -d '' d; do
    local pkg
    pkg="$(basename "${d}")"
    if [[ -d "${lib_cmake_dir}/${pkg}" ]]; then
      rm -rf "${share_cmake_dir:?}/${pkg}"
    fi
  done < <(find "${share_cmake_dir}" -mindepth 1 -maxdepth 1 -type d -print0)

  rmdir --ignore-fail-on-non-empty "${share_cmake_dir}" 2>/dev/null || true
}

PruneNonEssentialFiles() {
  rm -rf "${prefix_dir}/share/doc" "${prefix_dir}/share/licenses" "${prefix_dir}/share/pkgconfig" "${prefix_dir}/lib/pkgconfig"
}

WriteInstallManifestFromPrefix() {
  local out_path="${prefix_dir}/install_manifest.txt"
  rm -f "${out_path}"
  touch "${out_path}"

  (cd "${prefix_dir}" && find . \( -type f -o -type l \) -print) \
    | sed -e "s|^\.|${prefix_dir}|" \
    | sort -u \
    > "${out_path}"
}

EnsureLayoutDirs() {
  mkdir -p "${prefix_dir}/bin" "${prefix_dir}/lib" "${prefix_dir}/include" "${prefix_dir}/share/cmake"
}

AssertSharedLibrarySymlinks() {
  local lib_dir="${prefix_dir}/lib"
  if [[ ! -d "${lib_dir}" ]]; then
    echo "missing lib dir: ${lib_dir}" >&2
    exit 1
  fi

  local libs=("spdlog" "yaml-cpp" "Catch2")
  for base in "${libs[@]}"; do
    local versioned
    versioned=("${lib_dir}/lib${base}.so."*)
    if [[ "${versioned[0]}" == "${lib_dir}/lib${base}.so.*" ]]; then
      echo "missing versioned shared library: ${lib_dir}/lib${base}.so.<version>" >&2
      exit 1
    fi

    local unversioned="${lib_dir}/lib${base}.so"
    if [[ ! -e "${unversioned}" ]]; then
      echo "missing symlink: ${unversioned}" >&2
      exit 1
    fi
    if [[ ! -L "${unversioned}" ]]; then
      echo "expected symlink, got regular file: ${unversioned}" >&2
      exit 1
    fi
  done
}

echo "[third_party] prefix: ${prefix_dir}"
echo "[third_party] tar:    ${tarballs_dir}"
echo "[third_party] src:    ${src_dir}"

echo "[third_party] extracting sources"
ExtractTarball "${tarballs_dir}/abseil-cpp-20260107.1.tar.gz" "${src_dir}/abseil" 1
ExtractTarball "${tarballs_dir}/Catch2-3.13.0.tar.gz" "${src_dir}/catch2" 1
ExtractTarball "${tarballs_dir}/spdlog-1.17.0.tar.gz" "${src_dir}/spdlog" 1
ExtractTarball "${tarballs_dir}/json-3.12.0.tar.gz" "${src_dir}/json" 1
ExtractTarball "${tarballs_dir}/cpp-httplib-0.34.0.tar.gz" "${src_dir}/cpp-httplib" 1
ExtractTarball "${tarballs_dir}/yaml-cpp-yaml-cpp-0.9.0.tar.gz" "${src_dir}/yaml-cpp" 0

EnsureLayoutDirs

echo "[third_party] build+install abseil (static)"
ConfigureBuildInstall abseil "${src_dir}/abseil" "${build_dir}/abseil" \
  -DBUILD_SHARED_LIBS=OFF \
  -DABSL_BUILD_TESTING=OFF

echo "[third_party] build+install Catch2 (shared)"
ConfigureBuildInstall catch2 "${src_dir}/catch2" "${build_dir}/catch2" \
  -DBUILD_SHARED_LIBS=ON \
  -DCATCH_BUILD_TESTING=OFF \
  -DCATCH_INSTALL_DOCS=OFF \
  -DCATCH_INSTALL_EXTRAS=OFF

echo "[third_party] build+install spdlog (shared)"
ConfigureBuildInstall spdlog "${src_dir}/spdlog" "${build_dir}/spdlog" \
  -DBUILD_SHARED_LIBS=ON \
  -DSPDLOG_BUILD_SHARED=ON \
  -DSPDLOG_BUILD_STATIC=OFF \
  -DSPDLOG_BUILD_EXAMPLE=OFF \
  -DSPDLOG_BUILD_TESTS=OFF \
  -DSPDLOG_BUILD_BENCH=OFF

echo "[third_party] build+install yaml-cpp (shared)"
ConfigureBuildInstall yaml_cpp "${src_dir}/yaml-cpp" "${build_dir}/yaml-cpp" \
  -DBUILD_SHARED_LIBS=ON \
  -DYAML_BUILD_SHARED_LIBS=ON \
  -DYAML_CPP_BUILD_TESTS=OFF \
  -DYAML_CPP_BUILD_TOOLS=OFF

echo "[third_party] install nlohmann_json (header-only)"
ConfigureInstallOnly nlohmann_json "${src_dir}/json" "${build_dir}/json" \
  -DJSON_BuildTests=OFF

echo "[third_party] install cpp-httplib (header-only)"
ConfigureInstallOnly cpp_httplib "${src_dir}/cpp-httplib" "${build_dir}/cpp-httplib" \
  -DHTTPLIB_REQUIRE_OPENSSL=OFF

if [[ "${BUILD_VERIFY:-0}" == "1" ]]; then
  echo "[third_party] verify find_package"
  ConfigureBuildAndTest verify_find_package "${repo_root}/src/verify_find_package" "${build_dir}/verify_find_package"
fi

if [[ "${BUILD_DEMO:-0}" == "1" ]]; then
  echo "[third_party] build+test+install integrated_demo"
  ConfigureBuildTestInstall integrated_demo "${repo_root}/src/integrated_demo" "${build_dir}/integrated_demo"
fi

echo "[third_party] prune duplicated share/cmake entries"
PruneDuplicatedShareCmake

echo "[third_party] prune non-essential files"
PruneNonEssentialFiles

echo "[third_party] write install_manifest.txt"
WriteInstallManifestFromPrefix

echo "[third_party] check .so versioned symlinks"
AssertSharedLibrarySymlinks

echo "[third_party] done"
