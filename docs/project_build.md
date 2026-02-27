# 项目编译与交付（dist）说明

本文档描述“项目交付包”的编译与打包流程。

交付包输出目录：`prod_project/dist/`

交付包特点：

- 交付的是项目可执行文件与运行时所需的第三方动态库（`.so*`），而不是第三方库的开发包。
- 交付包内包含 `bin/`、`lib/`、`share/` 与 `manifest.txt`。

## 目录约定

- 三方源码压缩包目录：`prod_project/third_party/tarballs/*.tar.gz`
- 三方解压目录：`/home/xz_ys/3rd/src/`
- 三方构建目录：`/home/xz_ys/3rd/build/`
- 三方 install 前缀：`prod_project/third_party/ins/`

- 项目源码目录：`prod_project/src/`
- 项目构建目录（默认）：`prod_project/build/`
  - 可用环境变量 `BUILD_ROOT` 覆盖

## 第三方库编译（生成运行所需 .so/.a）

脚本：`prod_project/scripts/third_party/build_third_party.sh`

行为：

- 解压 6 个三方库到 `/home/xz_ys/3rd/src/`
- 构建到 `/home/xz_ys/3rd/build/`
- 安装到 `prod_project/third_party/ins/`

执行：

```bash
cd prod_project
./scripts/third_party/build_third_party.sh
```

说明：该脚本默认只构建/安装第三方库本身，不会构建项目 demo 或验证工程。需要时可显式开启：

```bash
BUILD_VERIFY=1 BUILD_DEMO=1 ./scripts/third_party/build_third_party.sh
```

## 项目编译（不构建第三方，只引用已安装前缀）

脚本：`prod_project/scripts/build_project.sh`

行为：

- 扫描 `prod_project/src/*/CMakeLists.txt` 并逐个构建
- 默认 `Release`，并运行 `ctest`
- 当 `INSTALL=1` 时执行 `cmake --install` 安装到 `INSTALL_PREFIX`（默认 `prod_project/out/`）

执行示例：

```bash
cd prod_project
./scripts/build_project.sh
```

如需指定构建目录与安装前缀：

```bash
BUILD_ROOT=/tmp/build INSTALL=1 INSTALL_PREFIX=/tmp/stage ./scripts/build_project.sh
```

## 项目交付包打包（dist）

脚本：`prod_project/scripts/pack_project.sh`

行为：

- 先执行项目安装到 staging 目录：`/home/xz_ys/3rd/stage/prod_project/`
- 扫描 staging 下的 `bin/*` 可执行文件，通过 `ldd` 找出来自 `prod_project/third_party/ins/lib` 的第三方动态库
- 将这些 `.so*`（含符号链接链）拷贝到交付包的 `lib/`
- 输出交付包到：`prod_project/dist/prod_project_delivery.tar.gz`
- 写入：
  - `share/ldd_<exe>.txt`：每个可执行文件的 ldd 结果
  - `manifest.txt`：交付包文件清单（相对路径）

执行：

```bash
cd prod_project
./scripts/pack_project.sh
```

## 交付包结构与运行

解压后目录结构：

- `prod_project/`
  - `bin/`：项目可执行文件
  - `lib/`：运行时第三方动态库（`.so*`）
  - `config/`：运行时默认配置（server/client 默认相对路径读取）
  - `share/`：配置与 ldd 报告
  - `manifest.txt`

运行示例（以 integrated_demo 为例）：

```bash
tar -xzf prod_project_delivery.tar.gz
cd prod_project
./prod_project/bin/integrated_demo_tests
./bin/integrated_demo_server
./bin/integrated_demo_client
```
