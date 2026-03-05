#!/usr/bin/env bash
set -euo pipefail

# Help function
show_help() {
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo
  echo "Options:"
  echo "  --check       Run in dry-run mode (check only, exit 1 on error)"
  echo "  --format      Run in format mode (modify files in-place, default)"
  echo "  --help        Show this help message"
  echo
  echo "Description:"
  echo "  Runs clang-format on all C/C++ source files in the project."
  echo "  Ignores build/, dist/, third_party/ directories."
}

# Parse arguments
MODE="format"
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
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Find clang-format
if ! command -v clang-format &> /dev/null; then
  echo "Error: clang-format not found. Please install it (e.g., sudo apt install clang-format)."
  exit 1
fi

echo "Running clang-format in ${MODE} mode..."

# Define directories to exclude
EXCLUDE_DIRS=(-name "build" -o -name "dist" -o -name "third_party" -o -name ".git" -o -name "cmake-build-*")

# Define file extensions to include
INCLUDE_EXTS=(-name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.cc" -o -name "*.hh")

# Find files
# We use a temporary file to store the list of files to avoid argument list too long issues if many files
FILES=$(find . \
  \( "${EXCLUDE_DIRS[@]}" \) -prune \
  -o \( "${INCLUDE_EXTS[@]}" \) -print)

if [[ -z "${FILES}" ]]; then
  echo "No source files found."
  exit 0
fi

# Count files
FILE_COUNT=$(echo "${FILES}" | wc -l)
echo "Found ${FILE_COUNT} files to process."

if [[ "${MODE}" == "check" ]]; then
  # dry-run mode, exit with error if changes needed
  # We check each file and print the name if it needs formatting.
  # We use exit code 1 to indicate failure for a single file, so xargs continues checking others.
  # xargs will return 123 if any invocation exited with 1-125.
  
  if echo "${FILES}" | xargs -P "$(nproc)" -I {} bash -c 'clang-format --dry-run -Werror "{}" >/dev/null 2>&1 || (echo "Style violation: {}"; exit 1)'; then
    echo "Code style check passed."
  else
    echo "Code style check failed. Run with --format to fix."
    echo "To see the exact changes for a file, run: clang-format <file> | diff -u <file> -"
    exit 1
  fi
else
  # format mode, modify files in place
  echo "${FILES}" | xargs -P "$(nproc)" -I {} clang-format -i "{}"
  echo "Code formatted successfully."
fi
