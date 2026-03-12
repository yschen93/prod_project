# Perf 与火焰图 (FlameGraph) 使用指南

本文档介绍了如何在 `prod_project` 中使用 `perf` 工具进行性能分析，并生成火焰图 (Flame Graph) 以可视化 CPU 热点。

## 1. 环境准备

在使用之前，请确保已安装以下工具：

1.  **perf**: Linux 内核自带的性能分析工具。
    - Ubuntu/Debian 安装: `sudo apt install linux-tools-common linux-tools-generic linux-tools-$(uname -r)`
    - WSL2 环境可能需要手动安装特定版本的 `linux-tools` (如 `linux-tools-6.8.0-101-generic`)。

2.  **FlameGraph**: 用于生成火焰图的 Perl 脚本工具集。
    - 本项目已将工具集成在 `tools/FlameGraph/` 目录下。
    - 核心脚本: `stackcollapse-perf.pl` (折叠堆栈) 和 `flamegraph.pl` (生成 SVG)。

## 2. 快速开始 (自动化脚本)

我们提供了一个自动化脚本，可以一键编译项目、采集数据并生成火焰图。

```bash
# 在项目根目录下执行
chmod +x scripts/generate_flamegraph.sh
./scripts/generate_flamegraph.sh
```

执行成功后，会在项目根目录生成 `perf_flame.svg` 文件。你可以直接用浏览器打开该文件查看性能热点。

## 3. 手动操作步骤

如果你需要更精细的控制，或者想了解脚本背后的原理，可以按照以下步骤手动操作。

### 第一步：编译目标程序

为了获得准确的调用栈信息，编译时需要开启调试符号 (`-g`) 并保留帧指针 (`-fno-omit-frame-pointer`)。我们在 CMake 中已经为 `perf_target` 配置好了。

```bash
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make perf_target
```

### 第二步：采集性能数据 (perf record)

使用 `perf record` 命令运行程序并采集 CPU 时钟事件。

```bash
# -F 99: 设置采样频率为 99Hz (避免与系统时钟中断频率重合)
# -e cpu-clock: 使用软件 CPU 时钟事件 (兼容性更好，特别是在 VM/WSL 中)
# -g: 记录调用栈 (Call Graph)
# --: 分隔符，后面跟要运行的命令
perf record -F 99 -e cpu-clock -g -- ./perf_target
```
*注：如果在 WSL2 中提示找不到 perf，尝试使用绝对路径，例如 `/usr/lib/linux-tools/6.8.0-101-generic/perf`。*

执行完成后，当前目录会生成一个 `perf.data` 文件。

### 第三步：解析数据 (perf script)

将二进制的 `perf.data` 转换为可读的文本格式。

```bash
perf script > out.perf
```

### 第三步：折叠堆栈 (Stack Collapse)

使用 FlameGraph 工具集中的 `stackcollapse-perf.pl` 将调用栈折叠成单行格式，以便后续处理。

```bash
# 假设 FlameGraph 工具在 ../tools/FlameGraph
../tools/FlameGraph/stackcollapse-perf.pl out.perf > out.folded
```

### 第五步：生成火焰图 (Generate SVG)

使用 `flamegraph.pl` 将折叠后的堆栈数据转换为 SVG 图片。

```bash
../tools/FlameGraph/flamegraph.pl out.folded > perf_flame.svg
```

## 4. 如何看懂火焰图

- **X 轴**：表示抽样数（Sample Count）。越宽的“火苗”代表该函数在 CPU 上运行的时间越长（或者被采样的次数越多）。
- **Y 轴**：表示调用栈的深度。顶层的“火苗”是正在执行的函数，下面的是它的父函数。
- **颜色**：通常是随机的暖色调，用于区分不同的帧，没有特殊的含义（除非使用了特定的调色板）。

**分析技巧**：
关注最宽的那些“平顶山”（Plateaus）。如果一个函数在顶部占据了很宽的区域，说明它是一个 CPU 热点，是性能优化的主要目标。
