# Cikaros Scoop Bucket

> Custom Scoop bucket with **pinned versions** following the official [`Versions`](https://github.com/ScoopInstaller/Versions) bucket pattern.
> 自定义 Scoop bucket，**版本锁定模式**，参照官方 [`Versions`](https://github.com/ScoopInstaller/Versions) 仓库。

**[English](#english) | [中文](#中文)**

---

## 中文

### 这是什么

一个 Scoop bucket，里面收录的 manifest 全部都是**版本锁定**的 —— 每个版本一个独立的 manifest 文件，文件名里直接带上具体版本号，无 `autoupdate`、无 `checkver`。

参照官方 `Versions` 仓库的思路：**即使本仓库后续推送了新版本的 manifest，老版本的 manifest 文件不会被改动，始终可以安装到原来那个具体的版本。**

专门为以下技术栈搭建：VS2015 + Win10 SDK 14393 + Qt 5.6.2 + JDK 15.0.1 + MySQL 8.0.21。

### 快速开始

```powershell
# 1) 一次性安装 Scoop 本身（如果还没装）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2) 添加本 bucket
scoop bucket add cikaros https://github.com/Cikaros/scoop-bucket

# 3) 从本 bucket 安装工具（VS2015 + Win10 SDK 需要管理员权限）
scoop install cikaros/vs2015-cpp
scoop install cikaros/windows10sdk-14393
scoop install cikaros/qt-5.6.2-msvc2015-64
scoop install cikaros/openjdk15
scoop install cikaros/mysql-8.0.21

# 4) 其余工具从官方 bucket 安装
scoop bucket add extras java versions
scoop install nodejs python git svn erlang rabbitmq
```

或者使用本仓库自带的 `scripts/install-all.ps1` 一键按依赖顺序安装全部 9 个工具。

### 本 bucket 中的 manifest

| 包名 | 版本 | 说明 |
|------|------|------|
| `vs2015-cpp` | 14.0.25431 | VS2015 Community + VC++/MFC/ATL 工作负载（系统级安装） |
| `windows10sdk-14393` | 10.0.14393.795 | Win10 SDK 周年更新版独立安装器 |
| `qt-5.6.2-msvc2015-64` | 5.6.2 | Qt 框架二进制（MSVC2015 x64），内嵌 QtIF 自动安装脚本 |
| `openjdk15` | 15.0.1.9 | Temurin OpenJDK 15.0.1+9 —— Oracle JDK 15.0.1 的替代品 |
| `mysql-8.0.21` | 8.0.21 | MySQL Community Server 8.0.21（版本锁定 + 数据持久化） |

以下工具**不在本 bucket**，因为官方 bucket 已经覆盖，直接用即可：

| 工具 | 命令 | 仓库 |
|------|------|------|
| Node.js | `scoop install nodejs` | main |
| Python | `scoop install python` | main |
| Git | `scoop install git` | main（Scoop 自身依赖） |
| SVN（命令行） | `scoop install svn` | extras |
| Tortoise SVN（GUI） | `scoop install tortoisesvn` | extras |
| Erlang | `scoop install erlang` | main |
| RabbitMQ | `scoop install rabbitmq` | extras |

### 推荐安装顺序

部分工具在安装时会检测其他工具的存在，按以下顺序装可以省去后期手动配置：

1. **VS2015 + C++ 工作负载** → 装好后 MSVC 编译器 + 注册表项就绪
2. **Windows 10 SDK 14393** → VS2015 下次启动会自动识别
3. **Qt 5.6.2** → 安装时 Qt 会检测 MSVC2015，自动在 Qt Creator 注册为 Kit
4. **JDK 15** → 独立
5. **MySQL 8.0.21** → 独立（装好后需手动初始化数据目录）
6. **Erlang** → RabbitMQ 前置依赖
7. **RabbitMQ** → 依赖 Erlang
8. **Node.js / Python / Git / SVN** → 互相独立，任意顺序

### 版本锁定是怎么实现的

每个 manifest 文件都是**自包含的、版本不可变**的：

- 文件名里直接带版本号（如 `mysql-8.0.21.json`）
- 不含 `autoupdate` 字段 → `scoop update` 不会去拉新版本
- 不含 `checkver` 字段 → 不主动检测上游版本
- `url` 字段指向固定的下载地址（或你自己镜像的 Release asset）

**对比官方 `main` 仓库**：`main` 里的 `mysql` manifest 追踪最新的 8.x，`scoop update mysql` 之后会自动升到最新版。本 bucket 的 `mysql-8.0.21` 永远是 8.0.21，不会自动升级。

**对比官方 `versions` 仓库**：`versions` 里的 `mysql80` 也是追踪 8.0.x 最新补丁，会自动升级。本 bucket 的 `mysql-8.0.21` 锁定到具体补丁版本，连小版本都不动。

### 如何添加新版本

参见 [CONTRIBUTING.md](CONTRIBUTING.md)。简要流程：

1. 复制一个最接近的 manifest 作为模板
2. 改文件名带新版本号
3. 改 `version`、`url`、`extract_dir`、`hash` 字段
4. 把 `notes` 里跟版本相关的内容改一遍
5. 推到 GitHub，CI 会自动验证 JSON

### Hash 校验说明

`vs2015-cpp`、`windows10sdk-14393`、`qt-5.6.2-msvc2015-64` 这三个 manifest **故意省略** `hash` 字段，因为对应的官方下载地址（微软 / Qt 归档）历史上有过迁移。处理方法：

```powershell
# 首次下载成功后，算出 SHA256：
Get-FileHash "$env:USERPROFILE\scoop\cache\<filename>.exe" -Algorithm SHA256

# 然后把 hash 字段加到 manifest 里：
#   "hash": "<算出的-sha256>"
```

或者安装时跳过 hash 校验：

```powershell
scoop install cikaros/vs2015-cpp --skip
```

### 重要注意事项

**VS2015 下载 URL 可能 404。** 微软偶尔会移动/下线 VS2015 安装包公开下载地址。如果 404：
1. 从 Visual Studio 订阅归档页下载 VS2015 ISO（如有订阅），或
2. 找社区镜像的 `vs_community.exe`（如果可能，对照微软公布的 SHA256 校验）
3. **镜像到你自己的 GitHub Release**：https://github.com/Cikaros/scoop-bucket/releases/new
4. 把 `bucket/vs2015-cpp.json` 里的 `url` 字段改成你 Release 的下载地址

这是本 bucket 里所有可能失效的 URL 的通用处理方式。

**Oracle JDK vs OpenJDK。** `openjdk15` manifest 装的是 Temurin (Adoptium OpenJDK 构建) 15.0.1+9，**不是 Oracle JDK 15.0.1**。Oracle 的 JDK 二进制包需要登录账号才能下载，没法在 manifest 里放公开 URL。Temurin 对几乎所有生产场景都 API/ABI 兼容。

如果非要 Oracle JDK 15.0.1：
1. 从 https://www.oracle.com/java/technologies/javase/jdk15-archive-downloads.html 下载（免费 Oracle 账号）
2. 挂到自己的 GitHub Release
3. 改 `bucket/openjdk15.json` 里的 `url` 和 `extract_dir`

**Qt 安装脚本。** Qt 5.6.2 安装器基于 Qt Installer Framework，不是 Inno / NSIS，有自己的一套静默模式。manifest 内嵌的 `installscript.qs` 自动选中 `qt.562.win64_msvc2015_64` 组件并自动点击所有向导页面。如果还弹 Qt 账号登录框，登录（免费）即可。

**替代方案（完全无交互，需要 Python）**：

```powershell
pip install aqtinstall
python -m aqt install-qt windows desktop 5.6.2 win64_msvc2015_64 --outputdir "C:\Qt\5.6.2"
```

**MySQL 初始化。** 装完后第一次跑：

```powershell
mysqld --initialize-insecure --console
mysqld --install MySQL
net start MySQL
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'your-password';"
```

`data`、`log`、`my.ini` 通过 `persist` 字段持久化，`scoop update mysql-8.0.21` 不会丢数据。

### 仓库结构

```
scoop-bucket/
├── .github/workflows/
│   └── validate-manifests.yml   # CI: push 时自动校验所有 manifest
├── bucket/
│   ├── vs2015-cpp.json
│   ├── windows10sdk-14393.json
│   ├── qt-5.6.2-msvc2015-64.json
│   ├── openjdk15.json
│   └── mysql-8.0.21.json
├── scripts/
│   └── install-all.ps1           # 一键按依赖顺序安装全部工具
├── AGENTS.md                     # AI Agent 维护指南（先读这个）
├── CONTRIBUTING.md               # 如何添加新版本 manifest
├── SKILL.md                      # manifest 构建详细参考（基于官方文档整理）
├── README.md
└── LICENSE
```

---

## English

### What is this

A Scoop bucket whose manifests are all **version-pinned** — one manifest file per concrete version, with the version baked into the filename. No `autoupdate`, no `checkver`.

Following the official [`Versions`](https://github.com/ScoopInstaller/Versions) bucket pattern: **even when this repo pushes new version manifests later, the old version manifest files remain untouched — they will always install the same specific version they were authored for.**

Built specifically for the toolchain: VS2015 + Win10 SDK 14393 + Qt 5.6.2 + JDK 15.0.1 + MySQL 8.0.21.

### Quick start

```powershell
# 1) One-time: install Scoop itself (if not yet installed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2) Add this bucket
scoop bucket add cikaros https://github.com/Cikaros/scoop-bucket

# 3) Install tools from this bucket (run as Administrator for VS2015 + Win10 SDK)
scoop install cikaros/vs2015-cpp
scoop install cikaros/windows10sdk-14393
scoop install cikaros/qt-5.6.2-msvc2015-64
scoop install cikaros/openjdk15
scoop install cikaros/mysql-8.0.21

# 4) Install the rest from official buckets
scoop bucket add extras java versions
scoop install nodejs python git svn erlang rabbitmq
```

Or use the included `scripts/install-all.ps1` to install all 9 tools in dependency order in one shot.

### Manifests in this bucket

| Package | Version | Notes |
|---------|---------|-------|
| `vs2015-cpp` | 14.0.25431 | VS2015 Community with VC++/MFC/ATL workload (system-level install) |
| `windows10sdk-14393` | 10.0.14393.795 | Anniversary Update SDK standalone installer |
| `qt-5.6.2-msvc2015-64` | 5.6.2 | Qt framework binary for MSVC2015 x64 (uses embedded QtIF auto-install script) |
| `openjdk15` | 15.0.1.9 | Temurin OpenJDK 15.0.1+9 — drop-in replacement for Oracle JDK 15.0.1 |
| `mysql-8.0.21` | 8.0.21 | MySQL Community Server 8.0.21 (version-pinned + data persistence) |

The following tools are **NOT** in this bucket because they're already in official Scoop buckets — use them directly:

| Tool | Command | Bucket |
|------|---------|--------|
| Node.js | `scoop install nodejs` | main |
| Python | `scoop install python` | main |
| Git | `scoop install git` | main (Scoop itself depends on it) |
| SVN (CLI) | `scoop install svn` | extras |
| Tortoise SVN (GUI) | `scoop install tortoisesvn` | extras |
| Erlang | `scoop install erlang` | main |
| RabbitMQ | `scoop install rabbitmq` | extras |

### Recommended installation order

Some of these tools detect others at install time. Following this order saves manual config later:

1. **VS2015 + C++ workload** → MSVC build tools ready, registry keys written
2. **Windows 10 SDK 14393** → VS2015 picks it up on next launch
3. **Qt 5.6.2** → during install, Qt detects MSVC2015 and registers as a kit in Qt Creator
4. **JDK 15** → independent
5. **MySQL 8.0.21** → independent (initialize data dir after install)
6. **Erlang** → required before RabbitMQ
7. **RabbitMQ** → depends on Erlang
8. **Node.js / Python / Git / SVN** → independent, install anytime

### How version pinning works

Each manifest file is **self-contained and version-immutable**:

- Filename includes the concrete version (e.g., `mysql-8.0.21.json`)
- No `autoupdate` field → `scoop update` will not pull new versions
- No `checkver` field → no upstream version detection
- `url` field points to a fixed download URL (or your own mirrored release asset)

**Compared to official `main` bucket**: `main`'s `mysql` manifest tracks latest 8.x — `scoop update mysql` will auto-upgrade to the latest. This bucket's `mysql-8.0.21` will always be 8.0.21.

**Compared to official `versions` bucket**: `versions`'s `mysql80` also tracks 8.0.x latest patch — auto-upgrades. This bucket's `mysql-8.0.21` is pinned to a specific patch — even the patch version doesn't move.

### How to add new versions

See [CONTRIBUTING.md](CONTRIBUTING.md). Quick summary:

1. Copy the closest manifest as a template
2. Rename to include the new version number
3. Update `version`, `url`, `extract_dir`, `hash` fields
4. Update version-specific content in `notes`
5. Push to GitHub — CI validates JSON automatically

### Hash verification notes

The `vs2015-cpp`, `windows10sdk-14393`, and `qt-5.6.2-msvc2015-64` manifests **intentionally omit** the `hash` field because the corresponding official download URLs (Microsoft / Qt archive) have a history of being moved. To fix:

```powershell
# After first successful download, compute the SHA256:
Get-FileHash "$env:USERPROFILE\scoop\cache\<filename>.exe" -Algorithm SHA256

# Then add to the manifest JSON:
#   "hash": "<computed-sha256>"
```

Or bypass hash verification for the install:

```powershell
scoop install cikaros/vs2015-cpp --skip
```

### Important caveats

**VS2015 download URL may 404.** Microsoft periodically moves/removes VS2015 installer URLs. If it 404s:
1. Download the VS2015 ISO from your Visual Studio Subscription archive (if you have one), OR
2. Find a community-mirrored `vs_community.exe` (verify checksum against Microsoft's published SHA256 if possible)
3. **Mirror it to your own GitHub release**: https://github.com/Cikaros/scoop-bucket/releases/new
4. Update the `url` field in `bucket/vs2015-cpp.json` to your release asset URL

This is the general pattern for any URL in this bucket that goes stale.

**Oracle JDK vs OpenJDK.** The `openjdk15` manifest installs **Temurin** (Adoptium's OpenJDK build) 15.0.1+9, **NOT Oracle JDK 15.0.1**. Oracle's JDK binaries require a login to download — there's no public URL we can put in a manifest. Temurin is API/ABI compatible for nearly all production uses.

If you strictly require Oracle JDK 15.0.1:
1. Download `jdk-15.0.1_windows-x64_bin.zip` from https://www.oracle.com/java/technologies/javase/jdk15-archive-downloads.html (free Oracle account required)
2. Host the zip on a GitHub release
3. Update `url` and `extract_dir` in `bucket/openjdk15.json`

**Qt installer script.** The Qt 5.6.2 installer uses Qt Installer Framework (NOT Inno Setup or NSIS), which has its own silent mode. The manifest embeds an `installscript.qs` that auto-selects the `qt.562.win64_msvc2015_64` component and auto-clicks through all wizard pages. If it prompts for a Qt account, log in (free).

**Alternative (fully headless, requires Python)**:

```powershell
pip install aqtinstall
python -m aqt install-qt windows desktop 5.6.2 win64_msvc2015_64 --outputdir "C:\Qt\5.6.2"
```

**MySQL setup.** After install, initialize once (run in an elevated shell if installing as a service):

```powershell
mysqld --initialize-insecure --console
mysqld --install MySQL
net start MySQL
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'your-password';"
```

The `data`, `log`, and `my.ini` paths are persisted via the `persist` field — your databases survive `scoop update mysql-8.0.21`.

### Repository structure

```
scoop-bucket/
├── .github/workflows/
│   └── validate-manifests.yml   # CI: validate all manifests on push
├── bucket/
│   ├── vs2015-cpp.json
│   ├── windows10sdk-14393.json
│   ├── qt-5.6.2-msvc2015-64.json
│   ├── openjdk15.json
│   └── mysql-8.0.21.json
├── scripts/
│   └── install-all.ps1           # One-shot installer for all tools
├── AGENTS.md                     # AI Agent maintenance guide (read this first)
├── CONTRIBUTING.md               # How to add new version manifests
├── SKILL.md                      # Manifest-building reference (synthesized from official docs)
├── README.md
└── LICENSE
```

## License

MIT — see [LICENSE](LICENSE).

The manifests themselves describe software with various licenses (LGPL, GPL, Freeware, Oracle EULA). You're responsible for compliance with each tool's license when installing via this bucket.
