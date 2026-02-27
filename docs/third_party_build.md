# 第三方库编译/安装/打包流程说明

本文档描述本仓库当前的第三方库集成方式（Linux + CMake），以及源码解压路径、安装路径、验证与打包流程。你可以直接修改“路径与变量”章节的约定（或修改脚本里的变量），我会根据你修改后的文档再同步调整脚本与目录。

## 目标与约束

- 6 个库：abseil、Catch2、cpp-httplib、nlohmann_json、spdlog、yaml-cpp
- 编译模式：统一 `Release`
- 产物类型：
  - abseil：静态库（`.a`）
  - Catch2 / spdlog / yaml-cpp：优先动态库（`.so` + 版本号符号链接）
  - cpp-httplib / nlohmann_json：header-only（不产出 `.so/.a`，但要有可 `find_package` 的 CMake 配置）
- 安装前缀：只允许在 `prod_project/third_party/ins` 内落地（其余目录不作为最终交付）

## 当前目录约定

### 源码包位置（输入）

- 三方源码压缩包：`/home/xz_ys/3rd/*.tar.gz`
  - `abseil-cpp-20260107.1.tar.gz`
  - `Catch2-3.13.0.tar.gz`
  - `cpp-httplib-0.34.0.tar.gz`
  - `json-3.12.0.tar.gz`
  - `spdlog-1.17.0.tar.gz`
  - `yaml-cpp-yaml-cpp-0.9.0.tar.gz`

### 解压路径（可修改点）

- 当前解压目录：`/home/xz_ys/3rd/src/`
  - abseil → `/home/xz_ys/3rd/src/abseil`
  - catch2 → `/home/xz_ys/3rd/src/catch2`
  - spdlog → `/home/xz_ys/3rd/src/spdlog`
  - json → `/home/xz_ys/3rd/src/json`
  - cpp-httplib → `/home/xz_ys/3rd/src/cpp-httplib`
  - yaml-cpp → `/home/xz_ys/3rd/src/yaml-cpp`

说明：`yaml-cpp-yaml-cpp-0.9.0.tar.gz` 的 tarball 根部没有顶层目录，因此解压时使用 `--strip-components=0`，其它库用 `--strip-components=1`。

### 构建目录（中间产物，可修改点）

- 当前构建目录：`/home/xz_ys/3rd/build/`
- 每个库都有独立 build 子目录（例如 `.../build/abseil`、`.../build/spdlog`）

### 安装目录（最终产物）

- 安装前缀：`prod_project/third_party/ins/`
- 结构要求：
  - `bin/`：demo 可执行文件
  - `lib/`：`.so*`、`.a`、以及 `lib/cmake/`（各库的 `*Config.cmake` 等）
  - `include/`：头文件
  - `share/cmake/`：仅保留“上游实际安装到 share/cmake”的包（当前为 `nlohmann_json`）
  - `install_manifest.txt`：最终保留文件的清单（由脚本按前缀目录扫描生成）

## CMake 配置（find_package）策略

- 目标：所有库都能通过 `find_package(<pkg> CONFIG REQUIRED)` 找到。
- 由于不同库上游的安装位置不同：
  - 大多数库将 `*Config.cmake` 安装到 `ins/lib/cmake/<pkg>/...`
  - nlohmann_json 将 `*Config.cmake` 安装到 `ins/share/cmake/nlohmann_json/...`
- 因此不再做 `lib/cmake → share/cmake` 的镜像拷贝，以避免重复。

## 编译/安装步骤（脚本执行逻辑）

脚本位置：`prod_project/scripts/third_party/build_third_party.sh`

### 关键变量（你可按需修改）

脚本内部核心路径变量：

- `tar_dir`：三方 tarball 目录（当前指向 `/home/xz_ys/3rd`）
- `src_dir`：解压目录（当前为 `${tar_dir}/src`）
- `build_dir`：构建目录（当前为 `${tar_dir}/build`，即 `/home/xz_ys/3rd/build`）
- `prefix_dir`：安装前缀（固定为 `prod_project/third_party/ins`）

### 每个库的 CMake 配置摘要

- abseil（静态）：
  - `-DBUILD_SHARED_LIBS=OFF`
  - `-DABSL_BUILD_TESTING=OFF`

- Catch2（动态）：
  - `-DBUILD_SHARED_LIBS=ON`
  - 关闭上游自测/文档安装：`-DCATCH_BUILD_TESTING=OFF -DCATCH_INSTALL_DOCS=OFF -DCATCH_INSTALL_EXTRAS=OFF`

- spdlog（动态）：
  - `-DBUILD_SHARED_LIBS=ON -DSPDLOG_BUILD_SHARED=ON -DSPDLOG_BUILD_STATIC=OFF`
  - 关闭 examples/tests/bench

- yaml-cpp（动态）：
  - `-DBUILD_SHARED_LIBS=ON -DYAML_BUILD_SHARED_LIBS=ON`
  - 关闭 tests/tools

- nlohmann_json（header-only，安装 CMake config）：
  - `-DJSON_BuildTests=OFF`

- cpp-httplib（header-only，安装 CMake config）：
  - `-DHTTPLIB_REQUIRE_OPENSSL=OFF`

## Demo / 验证

源码位置：

- Demo：`prod_project/src/integrated_demo`
- find_package 验证工程：`prod_project/src/verify_find_package`

脚本会在安装完成后做：

- `verify_find_package`：配置 + 编译 + `ctest`，确保 6 个包都能 `find_package` 且可链接
- `integrated_demo`：配置 + 编译 + `ctest`，并把可执行文件安装到 `ins/bin`
- `ldd`：输出 demo 可执行文件依赖到 `ins/share/integrated_demo/ldd_*.txt`

## 清理策略（减少无用文件）

脚本会在安装末尾做两类清理：

- CMake 配置去重：若 `ins/share/cmake/<pkg>` 与 `ins/lib/cmake/<pkg>` 同时存在，则删除 `share/cmake/<pkg>`（保留 `lib/cmake/<pkg>`）。
  - 例外：上游本来只装到 `share/cmake` 的包（当前是 `nlohmann_json`），不会被删除。

- 删除非必须目录（减少交付体积）：
  - `ins/share/doc`、`ins/share/licenses`
  - `ins/share/pkgconfig`、`ins/lib/pkgconfig`

如你希望保留其中某类文件（例如 license），你可以在此文档标注“必须保留”，我再据此调整脚本。

## 打包

脚本：`prod_project/scripts/third_party/pack_third_party.sh`

- 打包输入：`prod_project/third_party/ins`
- 打包输出：`prod_project/third_party/third_party_dependencies.tar.gz`
- 包内顶层为 `ins/`（便于在其他机器解压后直接使用 `ins` 作为前缀）
