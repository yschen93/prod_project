#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Runs clang-format on the project source files.
#   Can run in check mode (dry-run) or format mode (in-place).
#

set -euo pipefail

# --- Help Function ---
show_help() {
  echo "Usage: $(basename "$0") [OPTIONS] [PATH...]"
  echo
  echo "Options:"
  echo "  --check       Run in dry-run mode (check only, exit 1 on error, default)"
  echo "  --format      Run in format mode (modify files in-place)"
  echo "  --binary PATH Use a specific clang-format binary (absolute or relative path)"
  echo "  --help        Show this help message"
  echo
  echo "Arguments:"
  echo "  PATH          Optional. Specific file(s) or directory(s) to process."
  echo "                If not specified, defaults to current project root."
  echo
  echo "Description:"
  echo "  Runs clang-format on C/C++ source files."
  echo "  Ignores build/, dist/, third_party/ directories when scanning directories."
}

# --- Main Execution ---

# Parse arguments
MODE="check"
TARGET_PATHS=()
CLANG_FORMAT_BIN_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --format)
      MODE="format"
      shift
      ;;
    --binary)
      if [[ $# -lt 2 ]]; then
        echo "Error: --binary requires a PATH"
        show_help
        exit 1
      fi
      CLANG_FORMAT_BIN_OVERRIDE="$2"
      shift 2
      ;;
    --binary=*)
      CLANG_FORMAT_BIN_OVERRIDE="${1#--binary=}"
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
    *)
      # Collect non-option arguments as target paths
      TARGET_PATHS+=("$1")
      shift
      ;;
  esac
done

# Resolve project root and clang-format path
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
CLANG_FORMAT_BIN=""

if [[ -n "${CLANG_FORMAT_BIN_OVERRIDE}" ]]; then
  if [[ -x "${CLANG_FORMAT_BIN_OVERRIDE}" ]]; then
    CLANG_FORMAT_BIN="${CLANG_FORMAT_BIN_OVERRIDE}"
  elif [[ -x "${PROJECT_ROOT}/${CLANG_FORMAT_BIN_OVERRIDE}" ]]; then
    CLANG_FORMAT_BIN="${PROJECT_ROOT}/${CLANG_FORMAT_BIN_OVERRIDE}"
  else
    echo "Error: clang-format not found or not executable at '${CLANG_FORMAT_BIN_OVERRIDE}'"
    exit 1
  fi
else
  if [[ -x "${PROJECT_ROOT}/tools/bin/clang-format" ]]; then
    CLANG_FORMAT_BIN="${PROJECT_ROOT}/tools/bin/clang-format"
  elif command -v clang-format >/dev/null 2>&1; then
    CLANG_FORMAT_BIN="$(command -v clang-format)"
  else
    echo "Error: clang-format not found. Provide --binary PATH or install it in tools/bin."
    exit 1
  fi
fi

echo "Using clang-format: ${CLANG_FORMAT_BIN}"

DIFF_SUPPORTS_COLOR=0
if diff --help 2>/dev/null | grep -q -- "--color"; then
  DIFF_SUPPORTS_COLOR=1
fi

# Determine where to search
if [[ ${#TARGET_PATHS[@]} -eq 0 ]]; then
  # No paths specified, default to project root
  SEARCH_ROOTS=("${PROJECT_ROOT}")
  echo "No path specified, scanning entire project..."
else
  # Use specified paths
  SEARCH_ROOTS=("${TARGET_PATHS[@]}")
  echo "Scanning specified paths: ${TARGET_PATHS[*]}"
fi

echo "Running clang-format in ${MODE} mode..."

# Define directories to exclude
EXCLUDE_DIRS=(-name "build" -o -name "dist" -o -name "third_party" -o -name ".git" -o -name "cmake-build-*")

# Define file extensions to include
INCLUDE_EXTS=(-name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.cc" -o -name "*.hh")

# Find files
# We need to handle multiple search roots and potential relative paths
FILES=""
for ROOT in "${SEARCH_ROOTS[@]}"; do
  # Check if path exists
  if [[ ! -e "${ROOT}" ]]; then
    echo "Warning: Path '${ROOT}' does not exist, skipping."
    continue
  fi

  if [[ -d "${ROOT}" ]]; then
    # If it's a directory, search recursively
    FOUND=$(find "${ROOT}" \
      \( "${EXCLUDE_DIRS[@]}" \) -prune \
      -o \( "${INCLUDE_EXTS[@]}" \) -print)
    if [[ -n "${FOUND}" ]]; then
      FILES="${FILES} ${FOUND}"
    fi
  elif [[ -f "${ROOT}" ]]; then
    # If it's a file, just add it (assuming it's a source file)
    FILES="${FILES} ${ROOT}"
  fi
done

# Trim leading space
FILES=$(echo "${FILES}" | xargs)

if [[ -z "${FILES}" ]]; then
  echo "No source files found."
  exit 0
fi

# Count files
FILE_COUNT=$(echo "${FILES}" | wc -w)
echo "Found ${FILE_COUNT} files to process."

if [[ "${MODE}" == "check" ]]; then
  # check mode: show diffs for style violations
  VIOLATIONS_FOUND=0
  for FILE in ${FILES}; do
    # Run clang-format and check if XML output is empty (no replacements)
    if ! "${CLANG_FORMAT_BIN}" -output-replacements-xml "${FILE}" | grep -q "<replacement "; then
      continue
    fi
    
    echo "Style violation in: ${FILE}"
    # Show the diff
    if [[ ${DIFF_SUPPORTS_COLOR} -eq 1 ]]; then
      "${CLANG_FORMAT_BIN}" "${FILE}" | diff -u "${FILE}" - --color=auto || true
    else
      "${CLANG_FORMAT_BIN}" "${FILE}" | diff -u "${FILE}" - || true
    fi
    VIOLATIONS_FOUND=1
  done

  if [[ ${VIOLATIONS_FOUND} -eq 0 ]]; then
    echo "Code style check passed."
  else
    echo "Code style check failed. Run with --format to fix."
    exit 1
  fi
else
  # format mode
  # Use xargs for parallel processing
  # We need to be careful with paths containing spaces, but source files usually don't
  echo "${FILES}" | xargs -n 1 -P "$(nproc)" "${CLANG_FORMAT_BIN}" -i
  echo "Code formatted successfully."
fi
