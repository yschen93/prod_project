# 项目编译与交付（dist）说明

本文档描述“项目交付包”的编译与打包流程。

交付包输出目录：`prod_project/dist/`

## 交付包特点

- **开箱即用**: 解压后即可直接运行，无需安装额外依赖。
- **自包含依赖**: 包含所有运行时所需的第三方动态库（`.so` 文件）。
- **配置完备**: 自动包含默认配置文件。
- **目录结构**: 标准化的 `bin`, `lib`, `config` 结构。

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

1.  **安装项目**：调用 `build_project.sh` 将项目安装到临时目录。
2.  **智能依赖分析**：
    *   遍历 `bin` 目录下的所有可执行文件。
    *   使用 `ldd` 对照构建目录下的原始二进制文件进行分析。
    *   自动提取并拷贝所需的第三方动态库到 `lib/` 目录。
3.  **配置拷贝**：将配置文件拷贝到 `bin/config` 和根目录 `config`，确保无论在何处启动都能找到配置。
4.  **打包与清理**：生成 `prod_project_delivery.tar.gz` 并自动清理临时文件。

**执行命令：**

```bash
./scripts/pack_project.sh
```

## 交付包结构与运行

解压 `prod_project_delivery.tar.gz` 后，你会得到一个名为 `prod_project_delivery` 的目录：

```text
prod_project_delivery/
├── bin/
│   ├── integrated_demo_server
│   ├── integrated_demo_client
│   ├── config/              # 配置文件副本（供 bin 目录下运行时使用）
│   │   └── server.yaml
│   └── ...
├── lib/
│   ├── libspdlog.so.1.17
│   ├── libyaml-cpp.so.0.9
│   └── ...
├── config/                  # 配置文件副本（供根目录下运行时使用）
│   └── server.yaml
└── manifest.txt             # 文件清单
```

**运行说明：**

你可以选择以下任意一种方式运行，均无需手动设置 `LD_LIBRARY_PATH`：

**方式一：在根目录运行（推荐）**
```bash
tar -xzf prod_project_delivery.tar.gz
cd prod_project_delivery
./bin/integrated_demo_server
```

**方式二：进入 bin 目录运行**
```bash
cd prod_project_delivery/bin
./integrated_demo_server
```

二进制文件已内置 RPATH (`$ORIGIN/../lib`)，会自动寻找同级目录下的 `../lib` 库文件。
