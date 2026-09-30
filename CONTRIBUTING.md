# 贡献指南 / Contributing Guide

本 bucket 严格遵循**版本锁定模式**，参照官方 [`Versions`](https://github.com/ScoopInstaller/Versions) 仓库的约定。下面说明如何添加一个新的版本 manifest。

## 核心原则

1. **一个版本一个文件**：文件名直接包含具体版本号，如 `<name>-<version>.json`。本 bucket 当前收录的 manifest 列表见 [MANIFESTS.md](MANIFESTS.md)（由 CI 自动维护）。
2. **无 `autoupdate`、无 `checkver`**：版本锁定，不滚动。
3. **manifest 文件不可变**：发布后不能修改 `version` 字段或 `url` 字段。如果上游下载链接失效，要么改 `url` 指向你自己的 Release 镜像（保持 `version` 不变），要么新建一个 manifest（如 `<name>-<version>-mirror.json`）。
4. **`notes` 字段使用中文**：本 bucket 面向中文用户，所有 manifest 的 notes 字段统一用中文。
5. **URL 失效优先镜像到自己 Release**：不要依赖上游长期稳定。

## 添加新版本的步骤

### 1. 找一个最接近的 manifest 作为模板

例如要新增 `<name>-<new-version>`，找一个**类型最接近**的现有 manifest 作为模板。当前可用的 manifest 列表见 [MANIFESTS.md](MANIFESTS.md)。

### 2. 复制并重命名

```powershell
# 在仓库根目录，例如从 <existing-manifest>.json 复制出 <new-manifest>.json
Copy-Item bucket/<existing-manifest>.json bucket/<new-manifest>.json
```

### 3. 修改关键字段

打开新文件，修改以下字段：

| 字段 | 修改方式 |
|------|---------|
| `version` | 改成新的版本号字符串 |
| `description` | 把版本号描述改一遍 |
| `url` | 改成新版本的下载地址 |
| `extract_dir` | 如果是压缩包，改成新版本解压后的目录名（通常带新版本号） |
| `hash` | 留空（首次安装时用 `Get-FileHash` 算出来再回填），或者已知就填上 |
| `notes` 里跟版本相关的内容 | 比如 "本 manifest 已锁定到 X.Y.Z" 改成新版本号 |

### 4. 关键字段不能动

以下字段**不要加**（加了就破坏版本锁定承诺）：

- `autoupdate` ❌ —— 加了之后 `scoop update` 会自动升级版本
- `checkver` ❌ —— 加了之后 CI 会去检测上游新版本，但本 bucket 不需要这个功能

### 5. 验证 JSON 合法

```powershell
# 简单语法检查
Get-Content bucket/<new-manifest>.json -Raw | ConvertFrom-Json | Out-Null
Write-Host "JSON OK"
```

或者推到 GitHub 让 CI 自动验证。

### 6. 提交并推送

```powershell
git add bucket/<new-manifest>.json
git commit -m "新增 <new-manifest> manifest"
git push
```

CI 会在 GitHub Actions 里跑 `scoop cat <name>` 验证 manifest 是否能被 scoop 正确解析。如果失败，根据报错信息修改后重新推送。

## 模板示例

下面是版本锁定 manifest 的最小模板：

```json
{
    "version": "<具体版本号>",
    "description": "<工具名 + 版本号 + 简短说明>",
    "homepage": "<工具官网>",
    "license": {
        "identifier": "<SPDX 标识符>",
        "url": "<License 全文 URL>"
    },
    "notes": [
        "【版本锁定说明】",
        "本 manifest 已锁定到 <版本号>，无 autoupdate、无 checkver。",
        "即使本仓库后续推送其他版本 manifest，本 manifest 文件不会被改动，始终可以安装到 <版本号>。"
    ],
    "url": "<下载地址>",
    "extract_dir": "<如果是压缩包，填解压后的目录名；如果是 exe 安装器，删除本字段>"
}
```

## 命名规范

参照官方 `Versions` 仓库的命名习惯：

- **简单版本号**：`python39`、`mysql57`、`nodejs18`（无分隔符）
- **复杂版本号或带架构**：如 `<name>-<major>.<minor>.<patch>-<arch>.json`、`<name>-<build>.json`（带 `-` 分隔符）
- **本 bucket 的统一约定**：主版本号以下的所有版本号都用 `-` 连接（如 `<name>-<version>.json`），便于人眼阅读

新增 manifest 时，如果版本号只到主版本（如 `python39`），用无分隔符风格；如果带小版本号（如 `<name>-<version>.json`），用 `-` 分隔风格。

## 关于 hash 字段

本 bucket 故意让某些 manifest 省略 `hash` 字段（针对上游 URL 不稳定的工具，具体哪些见 [MANIFESTS.md](MANIFESTS.md) 字段速查表的 `hash` 列）。这是**有意为之**，不是疏漏。

但如果你新增的 manifest 对应的下载源稳定（如官方 CDN、GitHub Release 资产等），建议**填写 hash**：

```powershell
# 算出 SHA256
Get-FileHash <下载的文件> -Algorithm SHA256

# 加到 manifest：
{
    ...
    "url": "...",
    "hash": "abcdef0123456789...",
    ...
}
```

填了 hash 之后，CI 不会报警，用户安装时也会更安全。

## CI 验证流程

每次 push 到 main/master 分支，`.github/workflows/validate-manifests.yml` 会自动：

1. 在 Windows runner 上安装 Scoop
2. 把本 bucket 加进去
3. 对 `bucket/` 目录下每个 JSON 文件跑 `scoop cat <name>`，确保能被 scoop 正确解析
4. 列出所有可见的包名，确认能被搜索到

CI 失败的常见原因：

- JSON 语法错误（多了逗号、少了引号等）
- `version` 字段缺失
- `url` 字段缺失
- `extract_dir` 字段引用的路径与 `url` 实际内容不符（这条 CI 检测不到，但用户安装时会报错）

## 上游 URL 失效的处理流程

如果某个 manifest 的 `url` 上游不再可访问：

1. **优先**：把对应的安装包镜像到你自己的 GitHub Release
   - https://github.com/Cikaros/scoop-bucket/releases/new
   - 上传文件，获取下载 URL
2. 修改 manifest 的 `url` 字段指向新的 Release URL
3. **不要修改 `version` 字段**（保持版本号不变，符合版本锁定承诺）
4. 在 manifest 的 `notes` 里加一条说明，标注原始上游 URL 已失效，当前用的是镜像
5. 提交推送

如果新版本号也需要支持，**新建一个 manifest**（如 `<name>-<version>-mirror.json`），不要动原来的。

## 任何疑问

开 issue 即可：https://github.com/Cikaros/scoop-bucket/issues
