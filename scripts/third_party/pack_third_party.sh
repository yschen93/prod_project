#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${root_dir}/../.." && pwd)"
prefix_dir="${repo_root}/third_party/ins"

tar_name="third_party_dependencies.tar.gz"
out_path="${repo_root}/third_party/${tar_name}"

if [[ ! -d "${prefix_dir}" ]]; then
  echo "missing prefix: ${prefix_dir}" >&2
  exit 1
fi

rm -f "${out_path}"
mkdir -p "$(dirname "${out_path}")"
tar -czf "${out_path}" -C "${repo_root}/third_party" "ins"
echo "${out_path}"
