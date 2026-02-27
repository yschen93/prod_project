#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${root_dir}/.." && pwd)"
tar_dir="${repo_root}/../3rd"

tp_prefix="${repo_root}/third_party/ins"
stage_dir="${tar_dir}/stage/prod_project"
dist_dir="${repo_root}/dist"

tar_name="prod_project_delivery.tar.gz"
out_path="${dist_dir}/${tar_name}"

if [[ ! -d "${tp_prefix}" ]]; then
  echo "missing third_party prefix: ${tp_prefix}" >&2
  exit 1
fi

rm -rf "${stage_dir}"
mkdir -p "${stage_dir}" "${dist_dir}"

INSTALL=1 INSTALL_PREFIX="${stage_dir}" "${repo_root}/scripts/build_project.sh"

mkdir -p "${stage_dir}/lib"
mkdir -p "${stage_dir}/config"

if [[ -d "${stage_dir}/share/integrated_demo/config" ]]; then
  cp -a "${stage_dir}/share/integrated_demo/config/." "${stage_dir}/config/"
fi

CopyRuntimeLibsForBinary() {
  local exe_path="$1"

  if [[ ! -x "${exe_path}" ]]; then
    return
  fi

  local ldd_out
  ldd_out="$(ldd "${exe_path}" || true)"
  printf "%s\n" "${ldd_out}" > "${stage_dir}/share/ldd_$(basename "${exe_path}").txt"

  while IFS= read -r line; do
    local lib_token
    lib_token="$(printf "%s\n" "${line}" | awk '{print $1}')"
    local lib_path
    lib_path="$(printf "%s\n" "${line}" | awk '{print $3}')"
    if [[ -n "${lib_path}" && "${lib_path}" == ${tp_prefix}/lib/* ]]; then
      local base
      base="$(basename "${lib_path}")"
      local stem
      stem="$(printf "%s\n" "${base}" | sed -E 's/(\.so)(\..*)?$/\1/')"
      cp -a "${tp_prefix}/lib/${stem}"* "${stage_dir}/lib/" 2>/dev/null || true
      continue
    fi

    if [[ "${lib_token}" == lib*.so* ]]; then
      local stem
      stem="$(printf "%s\n" "${lib_token}" | sed -E 's/(\.so)(\..*)?$/\1/')"
      cp -a "${tp_prefix}/lib/${stem}"* "${stage_dir}/lib/" 2>/dev/null || true
    fi
  done <<< "${ldd_out}"
}

mkdir -p "${stage_dir}/share"

if [[ -d "${stage_dir}/bin" ]]; then
  while IFS= read -r -d '' exe; do
    CopyRuntimeLibsForBinary "${exe}"
  done < <(find "${stage_dir}/bin" -maxdepth 1 -type f -executable -print0)
fi

rm -f "${stage_dir}/manifest.txt"
(cd "${stage_dir}" && find . \( -type f -o -type l \) -print | sort -u) > "${stage_dir}/manifest.txt"

rm -f "${out_path}"
tar -czf "${out_path}" -C "$(dirname "${stage_dir}")" "$(basename "${stage_dir}")"
echo "${out_path}"
