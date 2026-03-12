# 代码格式化指南

本文档介绍如何使用 `clang-format` 工具在 `prod_project` 中保持一致的代码风格。

## 1. 工具要求

项目强制使用项目本地的 `clang-format` 工具，以确保团队成员使用完全一致的版本。

- **工具位置**: `tools/bin/clang-format`
- **配置文件**: 项目根目录下的 `.clang-format`

**注意**：你不需要手动安装系统级的 `clang-format`。脚本会自动使用 `tools/bin` 下的版本。如果该位置没有工具，脚本会报错。

## 2. 自动化脚本

提供了脚本 `scripts/format_project.sh` 来自动化格式化。

### 用法

```bash
# 检查整个项目（只读，显示差异，默认行为）
./scripts/format_project.sh

# 格式化整个项目（原地修改）
./scripts/format_project.sh --format

# 格式化指定文件或目录
./scripts/format_project.sh --format src/main.cpp include/
./scripts/format_project.sh --check src/integrated_demo/
```

### 功能特点
- **自动定位**: 脚本会自动切换到项目根目录执行，无论你在哪里运行它。
- **智能过滤**: 递归查找 C/C++ 文件，自动忽略 `build/`、`dist/`、`third_party/` 等目录。
- **差异展示**: 在 `--check` 模式下，如果有格式违规，会直接在终端输出彩色 `diff` 差异对比，方便快速定位问题。
- **并行处理**: 利用多核 CPU 并行处理，提高速度。

## 3. CMake 集成

你也可以通过 CMake 目标来运行格式化：

```bash
# 从构建目录运行
make format         # 对应 ./scripts/format_project.sh --format
make check-format   # 对应 ./scripts/format_project.sh --check
```

CMake 会自动将找到的 `clang-format` 路径传递给脚本（如果脚本需要）。但在最新版本中，脚本优先使用 `tools/bin/clang-format`。

## 4. 常见问题

- **"Error: clang-format not found at .../tools/bin/clang-format"**:
  请确保你已经下载或编译了 `clang-format` 可执行文件，并将其放置在项目的 `tools/bin/` 目录下。

- **如何忽略特定代码块？**:
  如果格式化破坏了某些特定代码的可读性（如矩阵定义），可以使用注释临时禁用：
  ```cpp
  // clang-format off
  int matrix[2][2] = {
      {1, 0},
      {0, 1}
  };
  // clang-format on
  ```
