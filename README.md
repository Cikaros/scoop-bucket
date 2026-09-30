# Cikaros Scoop Bucket

> **Version-pinned** Scoop bucket following the official [`Versions`](https://github.com/ScoopInstaller/Versions) bucket pattern.
> 版本锁定的 Scoop bucket，参照官方 [`Versions`](https://github.com/ScoopInstaller/Versions) 仓库的版本锁定模式。
>
> **Initial focus**: quick environment setup for compiling [ONLYOFFICE](https://www.onlyoffice.com/) on Windows.
> **前期目标**：在 Windows 上编译 [ONLYOFFICE](https://www.onlyoffice.com/) 所需的开发环境快速搭建。
>
> **Future expansion**: any software not available in official Scoop buckets, version-pinned.
> **后续扩展**：收录官方 Scoop bucket 中没有的、或官方会自动滚动版本的特定版本软件。
>
> Documentation is intentionally **not locked to a specific tech stack** — the bucket may grow to cover other tools as needs evolve.
> 文档**不锁定到特定技术栈** —— 后续可能根据需要扩展到其他工具。

**[English](#english) | [中文](#中文)**

---

## 中文

### 这是什么

一个 Scoop bucket，里面收录的 manifest 全部都是**版本锁定**的 —— 每个版本一个独立的 manifest 文件，文件名里直接带上具体版本号，无 `autoupdate`、无 `checkver`。

参照官方 `Versions` 仓库的思路：**即使本仓库后续推送了新版本的 manifest，老版本的 manifest 文件不会被改动，始终可以安装到原来那个具体的版本。**

### 项目定位

- **前期目标**：在 Windows 上编译 ONLYOFFICE 所需的开发环境快速搭建（VS2015 / Win10 SDK / Qt 5.6.2）。
- **后续扩展**：收录官方 bucket 中没有的、或官方会自动滚动版本的特定版本软件。

文档**不锁定到特定技术栈** —— 后续收录的工具可能与 ONLYOFFICE 编译无关，本 bucket 会随需求演进。

### 快速开始

```powershell
# 1) 一次性安装 Scoop 本身（如果还没装）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2) 添加本 bucket
scoop bucket add cikaros https://github.com/Cikaros/scoop-bucket

# 3) 从本 bucket 安装工具（完整可安装包列表见 [MANIFESTS.md](MANIFESTS.md)，系统级安装器需要管理员权限）
# 示例（请根据 MANIFESTS.md 里实际包名调整）：
# scoop install cikaros/<package-name>

# 或一键安装所有本 bucket 维护的工具：
# powershell -ExecutionPolicy Bypass -File scripts/install-all.ps1

# 4) 其他工具从官方 bucket 安装
scoop bucket add extras java versions
scoop install nodejs python git
```

或者使用本仓库自带的 `scripts/install-all.ps1` 一键按依赖顺序安装。

### 本 bucket 中的 manifest

本 bucket 收录的完整 manifest 列表由 CI 自动维护在 [MANIFESTS.md](MANIFESTS.md) 中（每次 push 后自动重新生成）。

后续会根据需要添加新的版本锁定 manifest，**不限于 ONLYOFFICE 编译场景**。任何官方 bucket 没有覆盖的、或官方会自动滚动版本的特定版本软件，都适合在本 bucket 收录。

### 不在本 bucket，由官方 bucket 覆盖

以下工具**官方 bucket 已经覆盖**，不在本 bucket 重复收录，直接用官方命令即可：

| 工具 | 命令 | 仓库 | 备注 |
|------|------|------|------|
| Node.js | `scoop install nodejs` | main | |
| Python | `scoop install python` | main | |
| Git | `scoop install git` | main | Scoop 自身依赖 |
| SVN（命令行） | `scoop install svn` | extras | |
| Tortoise SVN（GUI） | `scoop install tortoisesvn` | extras | |
| Erlang | `scoop install erlang` | main | |
| RabbitMQ | `scoop install rabbitmq` | extras | |
| JDK（任意版本） | `scoop install openjdk` | java | 多版本见 `versions` / `java` bucket |
| MySQL | `scoop install mysql` | main | 多版本见 `versions` bucket |

> 收录原则：**官方 bucket 已有的，不重复**；只收录官方没有、或会自动滚动版本的特定版本。

### 推荐安装顺序

部分工具在安装时会检测其他工具的存在，按以下顺序装可以省去后期手动配置：

1. **VS2015 + C++ 工作负载** → 装好后 MSVC 编译器 + 注册表项就绪
2. **Windows 10 SDK 14393** → VS2015 下次启动会自动识别
3. **Qt 5.6.2** → 安装时 Qt 会检测 MSVC2015，自动在 Qt Creator 注册为 Kit
4. **Node.js / Python / Git** → 独立，任意顺序
5. **Erlang** → RabbitMQ 前置依赖（如需 RabbitMQ）
6. **RabbitMQ** → 依赖 Erlang

### 版本锁定是怎么实现的

每个 manifest 文件都是**自包含的、版本不可变**的：

- 文件名里直接带版本号（如 `<name>-<version>.json`）
- 不含 `autoupdate` 字段 → `scoop update` 不会去拉新版本
- 不含 `checkver` 字段 → 不主动检测上游版本
- `url` 字段指向固定的下载地址（或你自己镜像的 Release asset）

**对比官方 `main` 仓库**：`main` 里的 `mysql` manifest 追踪最新的 8.x，`scoop update mysql` 之后会自动升到最新版。本 bucket 的 manifest 永远是发布时锁定的版本，不会自动升级。

**对比官方 `versions` 仓库**：`versions` 里的 `mysql80` 也是追踪 8.0.x 最新补丁，会自动升级。本 bucket 的 manifest 锁定到具体补丁版本，连小版本都不动。

### 如何添加新版本

参见 [CONTRIBUTING.md](CONTRIBUTING.md)。简要流程：

1. 复制一个最接近的 manifest 作为模板
2. 改文件名带新版本号
3. 改 `version`、`url`、`extract_dir`、`hash` 字段
4. 把 `notes` 里跟版本相关的内容改一遍
5. 推到 GitHub，CI 会自动验证 JSON

### Hash 校验说明

本 bucket 部分上游 URL 不稳定的 manifest **故意省略** `hash` 字段（具体哪些见 [MANIFESTS.md](MANIFESTS.md) 字段速查表中的 `installer` / `hash` 列）。这些 manifest 对应的官方下载地址（如微软 / Qt 归档）历史上有过迁移。处理方法：

```powershell
# 首次下载成功后，算出 SHA256：
Get-FileHash "$env:USERPROFILE\scoop\cache\<filename>.exe" -Algorithm SHA256

# 然后把 hash 字段加到 manifest 里：
#   "hash": "<算出的-sha256>"
```

或者安装时跳过 hash 校验：

```powershell
scoop install cikaros/<package-name> --skip
```

后续添加的 manifest，如果下载源稳定（如 Adoptium GitHub Release、官方 CDN 等），**强烈建议填 hash**。

### 重要注意事项

**部分上游 URL 可能 404。**（具体哪些 manifest 可能受影响，见 [MANIFESTS.md](MANIFESTS.md) 字段速查表）如果某 manifest 安装时报 404：
1. 从上游官网下载对应 ISO / 归档（如有订阅），或
2. 找社区镜像的可执行文件（如果可能，对照上游公布的 SHA256 校验）
3. **镜像到你自己的 GitHub Release**：https://github.com/Cikaros/scoop-bucket/releases/new
4. 把对应 `bucket/<name>.json` 里的 `url` 字段改成你 Release 的下载地址

这是本 bucket 里所有可能失效的 URL 的通用处理方式。

**Qt 类安装器脚本。** 如果某 manifest 使用 Qt Installer Framework（不是 Inno / NSIS），它有自己的一套静默模式。这类 manifest 在内嵌的 `installscript.qs` 会自动选中目标组件并自动点击所有向导页面。如果还弹 Qt 账号登录框，登录（免费）即可。

**Alternative (fully headless, requires Python)**:

```powershell
pip install aqtinstall
# 按 MANIFESTS.md 里对应的版本调整下命令
python -m aqt install-qt windows desktop <version> <kit> --outputdir "C:\Qt\<version>"
```

### 仓库结构

```
scoop-bucket/
├── .github/workflows/
│   └── validate-manifests.yml   # CI: 校验所有 manifest + 自动生成 MANIFESTS.md
├── bucket/                          # 版本锁定 manifest（完整列表见 MANIFESTS.md）
├── scripts/
│   └── install-all.ps1           # 一键按依赖顺序安装全部工具
├── AGENTS.md                     # AI Agent 维护指南（先读这个）
├── CONTRIBUTING.md               # 如何添加新版本 manifest
├── MANIFESTS.md                  # CI 自动生成的 manifest 列表（请勿手动编辑）
├── SKILL.md                      # manifest 构建详细参考（基于官方文档整理）
├── README.md
└── LICENSE
```

---

## English

### What is this

A Scoop bucket whose manifests are all **version-pinned** — one manifest file per concrete version, with the version baked into the filename. No `autoupdate`, no `checkver`.

Following the official [`Versions`](https://github.com/ScoopInstaller/Versions) bucket pattern: **even when this repo pushes new version manifests later, the old version manifest files remain untouched — they will always install the same specific version they were authored for.**

### Project positioning

- **Initial focus**: quick environment setup for compiling [ONLYOFFICE](https://www.onlyoffice.com/) on Windows (VS2015 / Win10 SDK / Qt 5.6.2).
- **Future expansion**: any software not available in official Scoop buckets, version-pinned.

The documentation is **not locked to a specific tech stack** — future additions may be unrelated to ONLYOFFICE build. The bucket evolves as needs arise.

### Quick start

```powershell
# 1) One-time: install Scoop itself (if not yet installed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2) Add this bucket
scoop bucket add cikaros https://github.com/Cikaros/scoop-bucket

# 3) Install tools from this bucket (full list in [MANIFESTS.md](MANIFESTS.md); system-level installers need admin)
# Example (adjust package name per MANIFESTS.md):
# scoop install cikaros/<package-name>

# Or install all tools maintained in this bucket in one shot:
# powershell -ExecutionPolicy Bypass -File scripts/install-all.ps1

# 4) Install the rest from official buckets
scoop bucket add extras java versions
scoop install nodejs python git
```

Or use the included `scripts/install-all.ps1` to install all tools in dependency order in one shot.

### Manifests in this bucket

The complete list of manifests in this bucket is automatically maintained in [MANIFESTS.md](MANIFESTS.md) (regenerated on every push by CI).

Future additions may cover other tools not necessarily related to ONLYOFFICE build. **Any software missing from official buckets, or where official buckets track rolling versions, fits this bucket.**

### Not in this bucket — covered by official buckets

The following tools are **already in official Scoop buckets** and are NOT re-included here:

| Tool | Command | Bucket | Notes |
|------|---------|--------|-------|
| Node.js | `scoop install nodejs` | main | |
| Python | `scoop install python` | main | |
| Git | `scoop install git` | main | Scoop itself depends on it |
| SVN (CLI) | `scoop install svn` | extras | |
| Tortoise SVN (GUI) | `scoop install tortoisesvn` | extras | |
| Erlang | `scoop install erlang` | main | |
| RabbitMQ | `scoop install rabbitmq` | extras | |
| JDK (any version) | `scoop install openjdk` | java | Multiple versions in `versions` / `java` buckets |
| MySQL | `scoop install mysql` | main | Multiple versions in `versions` bucket |

> Inclusion principle: **don't duplicate what official buckets already have**; only include software that's missing or where official buckets track rolling latest.

### Recommended installation order

Some of these tools detect others at install time. Following this order saves manual config later:

1. **VS2015 + C++ workload** → MSVC build tools ready, registry keys written
2. **Windows 10 SDK 14393** → VS2015 picks it up on next launch
3. **Qt 5.6.2** → during install, Qt detects MSVC2015 and registers as a kit in Qt Creator
4. **Node.js / Python / Git** → independent, install anytime
5. **Erlang** → required before RabbitMQ
6. **RabbitMQ** → depends on Erlang

### How version pinning works

Each manifest file is **self-contained and version-immutable**:

- Filename includes the concrete version (e.g., `<name>-<version>.json`)
- No `autoupdate` field → `scoop update` will not pull new versions
- No `checkver` field → no upstream version detection
- `url` field points to a fixed download URL (or your own mirrored release asset)

**Compared to official `main` bucket**: `main`'s `mysql` manifest tracks latest 8.x — `scoop update mysql` will auto-upgrade to the latest. This bucket's manifests are always pinned to the version they were authored for.

**Compared to official `versions` bucket**: `versions`'s `mysql80` also tracks 8.0.x latest patch — auto-upgrades. This bucket's manifests are pinned to a specific patch — even the patch version doesn't move.

### How to add new versions

See [CONTRIBUTING.md](CONTRIBUTING.md). Quick summary:

1. Copy the closest manifest as a template
2. Rename to include the new version number
3. Update `version`, `url`, `extract_dir`, `hash` fields
4. Update version-specific content in `notes`
5. Push to GitHub — CI validates JSON automatically

### Hash verification notes

Some manifests in this bucket (where upstream URLs are unstable) **intentionally omit** the `hash` field — see the `installer` / `hash` columns in [MANIFESTS.md](MANIFESTS.md) for specifics. These correspond to download sources (e.g., Microsoft / Qt archive) with a history of URL migration. To fix:

```powershell
# After first successful download, compute the SHA256:
Get-FileHash "$env:USERPROFILE\scoop\cache\<filename>.exe" -Algorithm SHA256

# Then add to the manifest JSON:
#   "hash": "<computed-sha256>"
```

Or bypass hash verification for the install:

```powershell
scoop install cikaros/<package-name> --skip
```

For future manifests, if the download source is stable (e.g., Adoptium GitHub release assets, official CDN), **filling the hash is strongly recommended**.

### Important caveats

**Some upstream URLs may 404.** (See [MANIFESTS.md](MANIFESTS.md) for which manifests may be affected.) If a manifest's install reports 404:
1. Download the corresponding ISO / archive from upstream (if you have a subscription), OR
2. Find a community-mirrored executable (verify checksum against the upstream's published SHA256 if possible)
3. **Mirror it to your own GitHub release**: https://github.com/Cikaros/scoop-bucket/releases/new
4. Update the `url` field in the corresponding `bucket/<name>.json` to your release asset URL

This is the general pattern for any URL in this bucket that goes stale.

**Qt-style installer script.** If a manifest uses Qt Installer Framework (NOT Inno Setup or NSIS), it has its own silent mode. The manifest's embedded `installscript.qs` auto-selects the target component and auto-clicks through all wizard pages. If it prompts for a Qt account, log in (free).

**Alternative (fully headless, requires Python)**:

```powershell
pip install aqtinstall
# 按 MANIFESTS.md 里对应的版本调整下命令
python -m aqt install-qt windows desktop <version> <kit> --outputdir "C:\Qt\<version>"
```

### Repository structure

```
scoop-bucket/
├── .github/workflows/
│   └── validate-manifests.yml   # CI: validate all manifests + auto-generate MANIFESTS.md
├── bucket/                          # version-pinned manifests (full list in MANIFESTS.md)
├── scripts/
│   └── install-all.ps1           # One-shot installer for all tools
├── AGENTS.md                     # AI Agent maintenance guide (read this first)
├── CONTRIBUTING.md               # How to add new version manifests
├── MANIFESTS.md                  # CI-auto-generated manifest list (do not edit manually)
├── SKILL.md                      # Manifest-building reference (synthesized from official docs)
├── README.md
└── LICENSE
```

## License

MIT — see [LICENSE](LICENSE).

The manifests themselves describe software with various licenses (LGPL, GPL, Freeware, Oracle EULA). You're responsible for compliance with each tool's license when installing via this bucket.
