# 项目编译与交付（dist）说明

本文档描述“项目交付包”的编译与打包流程。

交付包输出目录：`prod_project/dist/`

## 交付包特点

- 包含项目可执行文件。
- 包含运行时所需的第三方动态库（`.so` 文件），无需目标机器预装这些库。
- 目录结构自包含，便于部署。

## 目录约定

- 项目源码目录：`prod_project/src/`
- 构建目录：`prod_project/build/`
- 交付输出目录：`prod_project/dist/`

## 项目编译与构建

项目使用 `scripts/build_project.sh` 进行一键构建。该脚本会处理：

1.  使用 CMake 配置项目（自动下载并配置第三方依赖）。
2.  编译源码。
3.  运行测试。

**执行命令：**

```bash
./scripts/build_project.sh
```

## 项目交付包打包（dist）

脚本：`prod_project/scripts/pack_project.sh`

该脚本会执行以下步骤：

1.  **安装项目**：调用 `build_project.sh` 并设置安装前缀（staging area），将项目可执行文件安装到临时目录。
2.  **收集依赖库**：从构建目录（`build/_deps`）中扫描并收集所有第三方动态库（`.so`），复制到交付包的 `lib/` 目录。
3.  **生成清单**：生成包含包内所有文件的 `manifest.txt`。
4.  **打包**：将 staging 目录打包为 `prod_project_delivery.tar.gz`。

**执行命令：**

```bash
./scripts/pack_project.sh
```

## 交付包结构与运行

解压 `prod_project_delivery.tar.gz` 后，目录结构如下（示例）：

```text
stage/
├── bin/
│   ├── integrated_demo_server
│   ├── integrated_demo_client
│   └── ...
├── lib/
│   ├── libspdlog.so
│   ├── libyaml-cpp.so
│   ├── libCatch2.so
│   └── ...
├── share/
│   └── ...
└── manifest.txt
```

**运行说明：**

由于第三方库放置在 `lib/` 目录下，运行可执行文件时可能需要设置 `LD_LIBRARY_PATH`，或者依赖于构建时设置的 `RPATH`（`$ORIGIN/../lib`）。

```bash
# 解压
tar -xzf prod_project_delivery.tar.gz
cd stage

# 运行 (假设 RPATH 已正确设置)
./bin/integrated_demo_server
```
