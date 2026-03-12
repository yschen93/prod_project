#!/usr/bin/env bash
#
# Copyright (c) 2025 Your Company. All rights reserved.
#
# Author: Your Name <your.email@example.com>
# Created: 2025-01-01
# Description:
#   Generates a Flame Graph from perf data.
#   Compiles the project with debug info and runs perf record.
#

set -euo pipefail

# --- Constants ---
# Detect perf command
PERF_CMD="/usr/lib/linux-tools/6.8.0-101-generic/perf"
if [[ ! -x "${PERF_CMD}" ]]; then
    PERF_CMD="perf"
fi

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly FLAMEGRAPH_DIR="${PROJECT_ROOT}/tools/FlameGraph"
readonly OUTPUT_SVG="${PROJECT_ROOT}/perf_flame.svg"

# --- Main Execution ---

echo "Using perf command: ${PERF_CMD}"

# Ensure FlameGraph tools are available
if [[ ! -f "${FLAMEGRAPH_DIR}/flamegraph.pl" ]]; then
    echo "Error: FlameGraph tools not found in ${FLAMEGRAPH_DIR}"
    echo "Please ensure FlameGraph is installed (e.g., from tarball)"
    exit 1
fi

# Build the target
echo "Building perf_target..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make perf_target

# Run perf record
echo "Recording performance data..."
# -F 99: Sample at 99Hz
# -g: Call graph
# --: Separator for command
"${PERF_CMD}" record -F 99 -e cpu-clock -g -- ./perf_target

# Generate Flame Graph
echo "Generating Flame Graph..."
"${PERF_CMD}" script | "${FLAMEGRAPH_DIR}/stackcollapse-perf.pl" | "${FLAMEGRAPH_DIR}/flamegraph.pl" > "${OUTPUT_SVG}"

echo "Flame Graph generated at: ${OUTPUT_SVG}"
echo "You can view it in your browser."
