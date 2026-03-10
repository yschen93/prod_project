# Sanitizers Integration Guide for prod_project

This project includes integrated support for **AddressSanitizer (ASan)**, **UndefinedBehaviorSanitizer (UBSan)**, and **ThreadSanitizer (TSan)**. These tools help detect memory errors, undefined behavior, and concurrency issues during development.

## 1. Directory Structure

The sanitizer test cases are located in `src/sanitizers/`:
- `asan/`: Contains `asan_test.cpp` (Heap buffer overflow, memory leaks).
- `ubsan/`: Contains `ubsan_test.cpp` (Integer overflow, shift overflow, null pointer dereference).
- `tsan/`: Contains `tsan_test.cpp` (Data races, deadlocks).

## 2. Building the Targets

From the `build` directory, you can build the specific targets:

```bash
mkdir -p build && cd build
cmake ..
make asan_target ubsan_target tsan_target
```

## 3. Running and Expected Output

### AddressSanitizer (ASan)
**Purpose**: Detects memory corruption and leaks.
**Target**: `asan_target`

**How to run**:
```bash
./asan_target
```

**Expected Error Output (Example)**:
```text
==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x604000000028 at pc 0x55...
WRITE of size 4 at 0x604000000028 thread T0
    #0 0x55... in HeapBufferOverflow(int) src/sanitizers/asan/asan_test.cpp:13
    #1 0x55... in main src/sanitizers/asan/asan_test.cpp:34
...
SUMMARY: AddressSanitizer: heap-buffer-overflow src/sanitizers/asan/asan_test.cpp:13 in HeapBufferOverflow(int)
```

### UndefinedBehaviorSanitizer (UBSan)
**Purpose**: Detects standard-violating behavior like overflows or null dereferences.
**Target**: `ubsan_target`

**How to run**:
```bash
./ubsan_target
./ubsan_target null  # To trigger null pointer dereference
```

**Expected Error Output (Example)**:
```text
src/sanitizers/ubsan/ubsan_test.cpp:12:9: runtime error: signed integer overflow: 2147483647 + 1 cannot be represented in type 'int'
src/sanitizers/ubsan/ubsan_test.cpp:24:22: runtime error: shift exponent 32 is too large for 32-bit type 'int'
```

### ThreadSanitizer (TSan)
**Purpose**: Detects data races and deadlocks in multi-threaded code.
**Target**: `tsan_target`

**How to run**:
```bash
./tsan_target           # For data race
./tsan_target deadlock  # For deadlock simulation
```

**Expected Error Output (Example)**:
```text
WARNING: ThreadSanitizer: data race (pid=...)
  Write of size 4 at 0x55... by thread T2:
    #0 {lambda()#1}::operator()() src/sanitizers/tsan/tsan_test.cpp:17
...
  Previous write of size 4 at 0x55... by thread T1:
    #0 {lambda()#1}::operator()() src/sanitizers/tsan/tsan_test.cpp:17
```

## 4. Troubleshooting

- **ASan Leak Detection**: If leaks are not reported, try setting `export ASAN_OPTIONS=detect_leaks=1`.
- **TSan Memory Mapping**: If TSan fails with "unexpected memory mapping", ensure your system's ASLR or memory layout is compatible with TSan. This often requires setting `TSAN_OPTIONS="ignore_noninstrumented_modules=1"`.
- **Optimization**: These targets are built with `-O1 -g` to balance performance and debuggability as recommended for sanitizers.
