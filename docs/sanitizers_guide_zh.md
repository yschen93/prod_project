# prod_project Sanitizers 集成指南

该项目集成了对 **AddressSanitizer (ASan)**、**UndefinedBehaviorSanitizer (UBSan)** 和 **ThreadSanitizer (TSan)** 的支持。这些工具可以帮助在开发过程中检测内存错误、未定义行为和并发问题。

## 1. 目录结构

Sanitizer 测试用例位于 `src/sanitizers/` 目录下：
- `asan/`：包含 `asan_test.cpp`（堆缓冲区溢出、内存泄漏）。
- `ubsan/`：包含 `ubsan_test.cpp`（整数溢出、移位溢出、空指针解引用）。
- `tsan/`：包含 `tsan_test.cpp`（数据竞争、死锁）。

## 2. 构建目标

在 `build` 目录下，可以构建特定的目标：

```bash
mkdir -p build && cd build
cmake ..
make asan_target ubsan_target tsan_target
```

## 3. 运行与预期输出

### AddressSanitizer (ASan)
**目的**：检测内存损坏和泄漏。
**目标**：`asan_target`

**运行方式**：
```bash
./asan_target
```

**预期错误输出（示例）**：
```text
==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x604000000028 at pc 0x55...
WRITE of size 4 at 0x604000000028 thread T0
    #0 0x55... in HeapBufferOverflow(int) src/sanitizers/asan/asan_test.cpp:13
    #1 0x55... in main src/sanitizers/asan/asan_test.cpp:34
...
SUMMARY: AddressSanitizer: heap-buffer-overflow src/sanitizers/asan/asan_test.cpp:13 in HeapBufferOverflow(int)
```

### UndefinedBehaviorSanitizer (UBSan)
**目的**：检测违反标准的问题，如溢出或空指针解引用。
**目标**：`ubsan_target`

**运行方式**：
```bash
./ubsan_target
./ubsan_target null  # 触发空指针解引用
```

**预期错误输出（示例）**：
```text
src/sanitizers/ubsan/ubsan_test.cpp:12:9: runtime error: signed integer overflow: 2147483647 + 1 cannot be represented in type 'int'
src/sanitizers/ubsan/ubsan_test.cpp:24:22: runtime error: shift exponent 32 is too large for 32-bit type 'int'
```

### ThreadSanitizer (TSan)
**目的**：检测多线程代码中的数据竞争和死锁。
**目标**：`tsan_target`

**运行方式**：
```bash
./tsan_target           # 检测数据竞争
./tsan_target deadlock  # 检测死锁
```

**预期错误输出（示例）**：
```text
WARNING: ThreadSanitizer: data race (pid=...)
  Write of size 4 at 0x55... by thread T2:
    #0 {lambda()#1}::operator()() src/sanitizers/tsan/tsan_test.cpp:17
...
  Previous write of size 4 at 0x55... by thread T1:
    #0 {lambda()#1}::operator()() src/sanitizers/tsan/tsan_test.cpp:17
```

## 4. 常见问题排查

- **ASan 泄漏检测**：如果未报告泄漏，请尝试设置 `export ASAN_OPTIONS=detect_leaks=1`。
- **TSan 内存映射**：如果 TSan 报错 "unexpected memory mapping"，请确保系统的 ASLR 或内存布局与 TSan 兼容。通常需要设置 `TSAN_OPTIONS="ignore_noninstrumented_modules=1"`。
- **优化级别**：这些目标是使用 `-O0 -g` 构建的，以确保 Sanitizer 能够捕获所有预期的缺陷并提供准确的调试信息。
