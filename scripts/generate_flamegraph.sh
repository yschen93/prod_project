#!/bin/bash
set -e

# Detect perf command
PERF_CMD="/usr/lib/linux-tools/6.8.0-101-generic/perf"
if [ ! -x "$PERF_CMD" ]; then
    PERF_CMD="perf"
fi

echo "Using perf command: $PERF_CMD"

# Project root
PROJECT_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="$PROJECT_ROOT/build"
FLAMEGRAPH_DIR="$PROJECT_ROOT/tools/FlameGraph"
OUTPUT_SVG="$PROJECT_ROOT/perf_flame.svg"

# Ensure FlameGraph tools are available
if [ ! -f "$FLAMEGRAPH_DIR/flamegraph.pl" ]; then
    echo "Error: FlameGraph tools not found in $FLAMEGRAPH_DIR"
    echo "Please ensure FlameGraph is installed (e.g., from tarball)"
    exit 1
fi

# Build the target
echo "Building perf_target..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make perf_target

# Run perf record
echo "Recording performance data..."
# -F 99: Sample at 99Hz
# -g: Call graph
# --: Separator for command
$PERF_CMD record -F 99 -e cpu-clock -g -- ./perf_target

# Generate Flame Graph
echo "Generating Flame Graph..."
$PERF_CMD script | "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" | "$FLAMEGRAPH_DIR/flamegraph.pl" > "$OUTPUT_SVG"

echo "Flame Graph generated at: $OUTPUT_SVG"
echo "You can view it in your browser."
