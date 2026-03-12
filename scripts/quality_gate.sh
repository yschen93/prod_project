#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Runs code quality checks: formatting and testing.
#   Used as a gatekeeper for CI/CD or local pre-commit.
#

set -euo pipefail

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Main Execution ---

# Default behavior: Run tests. Formatting is optional but recommended for CI.
# Usage: ./scripts/quality_gate.sh [options]
# Options:
#   --format      Run clang-format check
#   --test        Run tests (default)
#   --all         Run all checks (format + tests)

RUN_FORMAT=0
RUN_TESTS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      RUN_FORMAT=1
      shift
      ;;
    --test)
      RUN_TESTS=1
      shift
      ;;
    --all)
      RUN_FORMAT=1
      RUN_TESTS=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

EXIT_CODE=0

if [[ "${RUN_FORMAT}" == "1" ]]; then
  echo "Running Code Format Check..."
  if ! "${SCRIPT_DIR}/format_project.sh" --check; then
    echo "Code format check failed."
    EXIT_CODE=1
  fi
fi

if [[ "${RUN_TESTS}" == "1" ]]; then
  echo "Running Tests..."
  if [[ -d "${REPO_ROOT}/build" ]]; then
    if ! (cd "${REPO_ROOT}/build" && ctest --output-on-failure); then
      echo "Tests failed."
      EXIT_CODE=1
    fi
  else
    echo "Build directory not found. Please build first."
    EXIT_CODE=1
  fi
fi

exit "${EXIT_CODE}"
