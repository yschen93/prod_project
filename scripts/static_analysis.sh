#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Runs clang-tidy on the project source files.
#   Uses CMake's compile_commands.json to perform accurate static analysis.
#

set -euo pipefail

# --- Help Function ---
show_help() {
  echo "Usage: $(basename "$0") [OPTIONS] [PATH...]"
  echo
  echo "Options:"
  echo "  --fix         Apply fixes suggested by clang-tidy (in-place modification)"
  echo "  --help        Show this help message"
  echo
  echo "Arguments:"
  echo "  PATH          Optional. Specific file(s) to analyze."
  echo "                If not specified, scans all relevant source files."
  echo
  echo "Description:"
  echo "  Runs clang-tidy static analysis."
  echo "  Requires a build directory with compile_commands.json."
}

# --- Main Execution ---

# Parse arguments
APPLY_FIXES=0
TARGET_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix)
      APPLY_FIXES=1
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
      TARGET_PATHS+=("$1")
      shift
      ;;
  esac
done

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${REPO_ROOT}/build"
readonly COMPILE_COMMANDS="${BUILD_DIR}/compile_commands.json"

# Check for compile_commands.json
if [[ ! -f "${COMPILE_COMMANDS}" ]]; then
  echo "Error: ${COMPILE_COMMANDS} not found."
  echo "Please build the project first with CMAKE_EXPORT_COMPILE_COMMANDS=ON."
  echo "You can use: ./scripts/build_project.sh"
  exit 1
fi

# Locate clang-tidy
CLANG_TIDY_BIN=""
if [[ -x "${REPO_ROOT}/tools/bin/clang-tidy" ]]; then
  CLANG_TIDY_BIN="${REPO_ROOT}/tools/bin/clang-tidy"
elif command -v clang-tidy >/dev/null 2>&1; then
  CLANG_TIDY_BIN="$(command -v clang-tidy)"
else
  echo "Error: clang-tidy not found."
  exit 1
fi

echo "Using clang-tidy: ${CLANG_TIDY_BIN}"

# Construct arguments
ARGS=("-p" "${BUILD_DIR}")
if [[ "${APPLY_FIXES}" == "1" ]]; then
  ARGS+=("--fix")
fi

# If target paths are provided, use them. Otherwise, let clang-tidy scan or use a file list.
# For simplicity, if no paths are provided, we can find all source files.
# However, run-clang-tidy script (if available) is better for parallel execution.

if [[ ${#TARGET_PATHS[@]} -gt 0 ]]; then
  echo "Analyzing specific files: ${TARGET_PATHS[*]}"
  "${CLANG_TIDY_BIN}" "${ARGS[@]}" "${TARGET_PATHS[@]}"
else
  echo "Analyzing all source files..."
  # We use git ls-files or find to get list of source files, excluding third_party
  # Then pipe to xargs for parallel execution is tricky with clang-tidy single invocation
  # Instead, we iterate over files in compile_commands.json or just src/
  
  find "${REPO_ROOT}/src" -name "*.cpp" -o -name "*.cc" | \
    grep -v "third_party" | \
    xargs -P "$(nproc)" -I {} "${CLANG_TIDY_BIN}" "${ARGS[@]}" {}
fi
