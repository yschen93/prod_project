# 代码格式化指南

本文档介绍如何使用 `clang-format` 工具在 `prod_project` 中保持一致的代码风格。

## 1. 安装

项目需要 `clang-format`。

### 检查安装
运行以下命令检查是否已安装：
```bash
clang-format --version
```

### 安装 (Linux/Ubuntu)
如果未安装，请通过以下方式安装：
```bash
sudo apt-get update
sudo apt-get install clang-format
```

## 2. 配置

代码风格在项目根目录下的 `.clang-format` 文件中定义。如需调整规则，请编辑此文件。
有关选项的完整列表，请参阅 [Clang-Format 样式选项](https://clang.llvm.org/docs/ClangFormatStyleOptions.html)。

主要规则（根据最新 .clang-format 更新）：
- **基准风格**: WebKit (自定义修改)。
- **缩进 (Indentation)**: 4 个空格 (不使用 Tab)。
- **列宽限制 (Column Limit)**: 67 个字符。
- **大括号 (Braces)**: 自定义风格
    - 函数: 另起一行 (AfterFunction: true)
    - 类/结构体/控制语句: 不换行 (AfterClass: false, AfterControlStatement: false)
    - Catch: 换行 (BeforeCatch: true)
- **标准 (Standard)**: C++20。
- **指针主要对齐 (Pointer Alignment)**: 左对齐 (`Type* ptr`).
- **访问修饰符偏移 (AccessModifierOffset)**: -4 (顶格书写 public/private)。
- **包含排序 (SortIncludes)**: 启用。

## 3. 自动化脚本

提供了脚本 `scripts/format_project.sh` 来自动化格式化。

### 用法

```bash
# 检查代码风格（空运行） - 如果发现违规，则退出代码为 1
./scripts/format_project.sh --check

# 格式化代码（原地修改）
./scripts/format_project.sh --format
```

### 功能
- 递归查找 C/C++ 文件（`.c`, `.cpp`, `.h`, `.hpp` 等）。
- 忽略 `build/`、`dist/`、`third_party/`。
- 并行处理以提高速度。

## 4. 构建系统集成

为了方便起见，添加了 CMake 目标。

```bash
# 从构建目录
make check-format   # 检查风格
make format         # 应用风格
```

## 5. 质量门禁 (Quality Gate)

对于 CI/CD 或预提交检查，请使用 `scripts/quality_gate.sh`。

```bash
# 检查格式并运行测试
./scripts/quality_gate.sh --all

# 仅检查格式
./scripts/quality_gate.sh --format
```

## 6. 示例

### 格式化前
```cpp
void foo() {
    int* x=nullptr;
      if(x) return;
}
```

### 格式化后
```cpp
void foo()
{
    int* x = nullptr;
    if (x) {
        return;
    }
}
```

## 7. 故障排除

- **"clang-format not found"**: 确保它在您的 PATH 中。
- **冲突**: 如果格式化更改了不应更改的代码，请在块周围使用 `// clang-format off` 和 `// clang-format on` 注释。

```cpp
// clang-format off
int    matrix[2][2] = {
  {1, 0},
  {0, 1}
};
// clang-format on
```
