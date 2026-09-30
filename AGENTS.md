# AGENTS.md — 项目维护 Agent 指南

> 本文件用于引导 AI Agent（Claude / GPT / Cursor 等）维护本项目（`Cikaros/scoop-bucket`）。
> Agent 在执行任何维护任务前，**必须先读完本文件**。

---

## 1. 项目概览

### 1.1 这是什么

一个 Scoop bucket，收录 Windows 开发环境工具的 **版本锁定 manifest**。专门服务于以下技术栈：

- VS2015（C++ 工作负载）
- Windows 10 SDK 14393.795
- Qt 5.6.2（MSVC2015 x64）
- JDK 15.0.1（用 Temurin OpenJDK 替代 Oracle JDK）
- MySQL 8.0.21

### 1.2 核心原则（不可妥协）

1. **版本锁定**：每个 manifest 文件名带具体版本号，`version` 字段与文件名中的版本号一致。无 `autoupdate`、无 `checkver`。
2. **manifest 不可变**：manifest 发布后，`version` 字段绝对不能改。上游 URL 失效时只能改 `url`（且只能指向"同一版本的镜像"），不能升级版本。
3. **中文优先**：所有 manifest 的 `notes` 字段用中文；README 是中英双语；CONTRIBUTING / SKILL / AGENTS 用中文（技术字段名保留英文）。
4. **不重复造轮子**：官方 `main` / `extras` / `java` / `versions` bucket 已经覆盖的工具（nodejs、python、git、svn、erlang、rabbitmq 等），**不在本 bucket 收录**。本 bucket 只收录官方没有、或官方会自动滚动版本的特定版本。

### 1.3 必读文档（按重要性排序）

| 文件 | 何时读 |
|------|--------|
| **本文件 (AGENTS.md)** | 开始任何维护任务前 |
| `SKILL.md` | 编写或修改 manifest 时 |
| `CONTRIBUTING.md` | 新增 manifest 时 |
| `README.md` | 需要理解项目对外宣传口径时 |
| `bucket/*.json` | 作为编写新 manifest 的模板参考 |

---

## 2. 维护任务清单

按出现频率排序。Agent 接到任务时，先在下面找到对应章节，按流程执行。

### 任务 A：添加新版本 manifest（已有工具的新版本）

**触发场景**：用户说"加一个 mysql 8.0.30" 或 "qt 5.9.9 也支持一下"。

**执行步骤**：

1. 找一个最接近的现有 manifest 作为模板（比如要加 mysql-8.0.30，就复制 `bucket/mysql-8.0.21.json`）。
2. 改文件名为新版本号：`bucket/mysql-8.0.30.json`。
3. 修改以下字段：
   - `version` → 新版本号字符串
   - `description` → 更新版本号描述
   - `url` → 新版本下载地址（**必须先验证 URL 有效**）
   - `extract_dir` → 如果是 zip 包，更新解压后目录名（通常带新版本号）
   - `notes` 里【版本锁定说明】段的版本号也要改
4. 删除 `hash` 字段（先留空，让用户首次安装时算出再回填，或者在本地算好直接填）。
5. JSON 语法校验：
   ```powershell
   Get-Content bucket/mysql-8.0.30.json -Raw | ConvertFrom-Json | Out-Null
   Write-Host "JSON OK"
   ```
6. 提交并推送，CI 自动跑 `scoop cat <name>` 验证。

**关键约束**：
- ❌ 不要碰被复制的原 manifest 文件
- ❌ 不要加 `autoupdate` 或 `checkver` 字段
- ❌ 不要用通用名（如 `mysql.json`）覆盖原 manifest

### 任务 B：修复失效的下载 URL

**触发场景**：用户报告某个 manifest 安装时报 404，或 CI 报 hash 不匹配（其实是因为 URL 重定向到 404 页面）。

**执行步骤**：

1. 用 `curl -I <url>` 或浏览器访问 manifest 的 `url` 字段，确认确实失效。
2. 找新地址：
   - 优先去上游官网找新归档地址
   - 如果上游彻底下线，找可信镜像（如社区镜像站）
   - 最后手段：**把安装包镜像到 `github.com/Cikaros/scoop-bucket/releases`**，用 Release asset URL
3. 修改 manifest 的 `url` 字段。**不要改 `version` 字段。**
4. 在 `notes` 字段开头加一条说明：
   ```
   "【URL 变更记录】",
   "原始上游 URL 已失效，当前 URL 指向 GitHub Release 镜像。",
   "镜像的安装包 SHA256 与上游发布时一致，请放心使用。",
   ```
5. 重新算 hash（如果新 URL 内容与旧的不同），更新 `hash` 字段。
6. 提交、推送，观察 CI。

**关键约束**：
- ✅ 改 `url` 指向镜像，OK
- ✅ 改 `hash` 重新校验，OK
- ❌ 改 `version` 不行 — 这是版本锁定承诺

### 任务 C：算出并回填 hash

**触发场景**：某个 manifest 当前没有 `hash` 字段（VS2015 / Win10 SDK / Qt 5.6.2），用户希望补全。

**执行步骤**：

1. 在 Windows 机器上首次跑 `scoop install cikaros/<name> --skip`，下载安装包。
2. 找到缓存路径：
   ```powershell
   Get-ChildItem $env:USERPROFILE\scoop\cache\*<关键词>*
   ```
3. 计算 SHA256：
   ```powershell
   Get-FileHash <缓存文件路径> -Algorithm SHA256
   ```
4. 在 manifest 的 `url` 字段后加上：
   ```json
   "hash": "<算出的 SHA256>",
   ```
5. 提交、推送。

### 任务 D：处理 CI 失败

CI 在 `.github/workflows/validate-manifests.yml`，每次 push 自动跑 `scoop cat <name>` 校验所有 manifest。

**常见失败原因**：

| 错误信息 | 原因 | 修复 |
|---------|------|------|
| `ConvertFrom-Json : Invalid JSON` | JSON 语法错误（多了逗号、少了引号等） | 用 JSON 校验器定位错误行，修复 |
| `scoop cat` 报"Required property 'version' not found" | 缺 `version` 字段 | 补上 |
| `scoop cat` 报"Required property 'url' not found" | 缺 `url` 字段 | 补上 |
| `scoop cat` 报其他字段错误 | 字段类型不对（如 `bin` 不是数组） | 参照 SKILL.md 第 2 章字段总览修复 |

**调试流程**：

1. 在 CI 失败的 PR / commit 上点 "Actions" → 找到失败的 job → 看 "Validate each manifest JSON" 步骤的输出。
2. 输出会告诉你是哪个 manifest 失败、具体什么报错。
3. 本地复现：
   ```powershell
   scoop bucket add mybucket <仓库本地路径>
   scoop cat <失败的 manifest 名>
   ```
4. 修复后重新推送。

### 任务 E：添加全新工具的 manifest

**触发场景**：用户说"加一个 cmake 3.x" 或 "支持 7zip 19.00"。

**执行步骤**：

1. **先查官方 bucket 是否已经有**：
   - https://github.com/ScoopInstaller/Main
   - https://github.com/ScoopInstaller/Extras
   - https://github.com/ScoopInstaller/Versions
   - https://github.com/ScoopInstaller/Java

   如果官方有，**不要在本 bucket 收录**，告诉用户用官方的。

2. 如果官方没有该特定版本，确定本 bucket 应该收录。参照 `SKILL.md` 第 16 章模板选一个最接近的。

3. 决定文件名：
   - 主版本号以下都用 `-` 分隔：`cmake-3.20.5.json`、`mysql-8.0.21.json`
   - 简单主版本号（如 `python39`）：可以用无分隔符风格
   - **本 bucket 统一约定用 `-` 分隔风格**，便于人眼阅读

4. 决定 manifest 类型（参照 SKILL.md 第 6 章）：
   - 便携式 zip → 见 16.1 模板
   - 系统级 EXE 安装器 → 见 16.2 模板
   - 复杂自定义安装器 → 参考 `bucket/qt-5.6.2-msvc2015-64.json`

5. 写 manifest，包含所有 ✅ 必填字段（见 SKILL.md 第 2 章）。

6. 在 `notes` 字段至少包含：
   - 【版本锁定说明】（参照现有 manifest 的写法）
   - 【安装路径】（如果是系统级安装器）
   - 【URL 提示】（如果上游 URL 可能失效）
   - 【Hash 提示】（如果故意省略 hash）

7. 更新 `README.md` 的 manifest 表格，把新包加进去。

8. JSON 语法校验 + 推送等 CI。

### 任务 F：升级某个 manifest 的版本

**触发场景**：用户说"把 mysql 8.0.21 升到 8.0.30"。

**正确处理**：
- ❌ **不允许**修改原 manifest 的 `version` 字段（违反版本锁定承诺）
- ✅ **正确做法**：按"任务 A"流程，**新建一个 manifest**（如 `bucket/mysql-8.0.30.json`），原 `bucket/mysql-8.0.21.json` 保持不变

如果用户坚持要"原地升级"（即改原 manifest 的版本），向用户解释本 bucket 的版本锁定原则，建议改用官方 `main` 或 `versions` bucket。

### 任务 G：更新 README 或 CONTRIBUTING

**触发场景**：项目对外文档需要修订。

**执行步骤**：
1. README 是中英双语，改中文段的同时必须改英文段，两段保持内容一致
2. CONTRIBUTING 是纯中文
3. 改完后重新读一遍，确保链接没失效（GitHub 上的 wiki URL 偶尔会迁移）

---

## 3. 编码规范

### 3.1 Manifest 字段顺序（推荐）

为了所有 manifest 风格统一、便于阅读，字段按以下顺序排列：

```
version
description
homepage
license
notes
url
hash
extract_dir / extract_to
pre_install
installer
post_install
env_set
env_add_path
persist
bin
shortcuts
architecture（如有）
```

参照 `bucket/mysql-8.0.21.json` 的字段顺序。

### 3.2 notes 字段结构（推荐）

中文 notes 用方括号小标题分段，每段后跟具体内容。参照现有 manifest：

```
【版本锁定说明】
本 manifest 已锁定到 X.Y.Z，无 autoupdate、无 checkver。
即使本仓库后续推送其他版本 manifest，本 manifest 文件不会被改动，始终可以安装到 X.Y.Z。

【安装路径】
...

【URL 提示】
...

【Hash 提示】
...
```

### 3.3 JSON 缩进与引号

- 缩进：4 空格（参照现有 manifest）
- 字符串：双引号
- 路径中的反斜杠：在 JSON 中要写双反斜杠 `\\`，例如 `"bin\\mysql.exe"`

### 3.4 禁用字段清单

以下字段**绝对不能出现在本 bucket 的任何 manifest 中**：

- `autoupdate` — 违反版本锁定
- `checkver` — 违反版本锁定
- `_comment` — 已废弃，用 `##` 代替
- `msi` — 已废弃，省略即可触发 zip 解压行为
- `cookie` — 官方未文档化，不要用

CI 不强制检查这些字段，但代码审查时必须拦截。

---

## 4. 常用命令速查

### 4.1 添加本 bucket 并安装

```powershell
scoop bucket add cikaros https://github.com/Cikaros/scoop-bucket
scoop install cikaros/<name>
```

### 4.2 跳过 hash 校验安装

```powershell
scoop install cikaros/<name> --skip
```

### 4.3 验证 manifest 能被 scoop 解析

```powershell
scoop cat <name>
```

### 4.4 查看 manifest 字段（解析后）

```powershell
scoop info <name>
```

### 4.5 计算 SHA256

```powershell
Get-FileHash <文件路径> -Algorithm SHA256
```

### 4.6 JSON 语法本地校验

PowerShell：

```powershell
Get-Content bucket/<name>.json -Raw | ConvertFrom-Json | Out-Null
Write-Host "JSON OK"
```

Python（在 Linux/WSL 上）：

```bash
python3 -c "import json; json.load(open('bucket/<name>.json'))"
```

### 4.7 不使用缓存重新下载

```powershell
scoop install <name> --no-cache-dir
```

### 4.8 列出本 bucket 所有包

```powershell
scoop search ""
```

---

## 5. 决策记录

记录关键设计决策的原因，便于未来维护时理解为什么这么设计。

### 5.1 为什么不用 `autoupdate` / `checkver`

**决策**：本 bucket 所有 manifest 都不写 `autoupdate` 和 `checkver` 字段。

**原因**：
- 用户需求是"即使仓库更新也不影响各个版本的安装"
- `autoupdate` 会让 `scoop update` 自动升级到上游新版本，违背版本锁定承诺
- `checkver` 是 autoupdate 的前置依赖，没用自然不需要

**对比**：官方 `versions` bucket 的 `mysql80` 也写 `checkver` + `autoupdate`，会自动跟 8.0.x 最新补丁。本 bucket 的 `mysql-8.0.21` 锁到具体补丁，连小版本都不动。

### 5.2 为什么文件名用 `-` 分隔风格

**决策**：文件名形如 `mysql-8.0.21.json`，而不是 `mysql8021.json`（官方 versions bucket 风格）。

**原因**：
- 本 bucket 是版本锁定，要锁到具体补丁版本，版本号本来就长
- `mysql-8.0.21` 比 `mysql8021` 可读性高得多
- 用户安装命令 `scoop install cikaros/mysql-8.0.21` 也更清晰

### 5.3 为什么 `oracle-jdk15` 改名为 `openjdk15`

**决策**：第一版 manifest 叫 `oracle-jdk15.json`，第二版改为 `openjdk15.json`。

**原因**：
- 实际安装的是 Temurin (Adoptium OpenJDK 构建) 15.0.1+9，**不是** Oracle JDK 15.0.1
- Oracle JDK 需要登录账号下载，没法在 manifest 里放公开 URL
- 命名为 `oracle-jdk15` 但装的是 OpenJDK，会误导用户
- 改名为 `openjdk15` 更诚实，与官方 `java` bucket 的 `openjdk15` 命名也一致
- notes 里清楚说明：如果非要 Oracle JDK，自己下载镜像到 Release

### 5.4 为什么 VS2015 / Win10 SDK / Qt 的 manifest 省略 `hash`

**决策**：这三个 manifest 故意不写 `hash` 字段，notes 里告诉用户用 `--skip` 安装。

**原因**：
- 微软和 Qt 的归档 URL 历史上有过迁移，hash 字段填了反而会过期
- 如果上游静默换了包内容（虽然不常见），hash 校验会失败
- 留空 + `--skip` 让用户自己决定是否信任下载源
- MySQL / OpenJDK 的下载源稳定（MySQL 官网归档 + Adoptium GitHub Release），所以这俩填了 hash

### 5.5 为什么用 GitHub Release 镜像失效 URL

**决策**：当上游 URL 失效时，统一改指向 `github.com/Cikaros/scoop-bucket/releases` 上的镜像。

**原因**：
- GitHub Release 资产 URL 稳定、CDN 加速、永久有效（除非主动删除）
- 用户不需要登录就能下载
- 跨地域访问性能比上游官网通常更好
- 便于审计（每个镜像对应一个 Release，可以加 SHA256 校验说明）

### 5.6 为什么 README 是中英双语，其他文档纯中文

**决策**：README 双语，CONTRIBUTING / SKILL / AGENTS 纯中文。

**原因**：
- README 是项目门面，国际用户也会看到，需要双语
- CONTRIBUTING / SKILL / AGENTS 是给维护者看的，本 bucket 维护者是中文用户为主
- 国际用户如果要贡献，让他们读 README 英文段了解项目后，再用翻译工具读 CONTRIBUTING 即可

### 5.7 为什么 CI 用 `scoop cat` 而不是 schema 校验

**决策**：CI 跑 `scoop cat <name>` 验证 manifest。

**原因**：
- `scoop cat` 是 scoop 内置的 manifest 解析器，最贴近实际行为
- 如果用第三方 JSON schema 校验，可能漏掉 scoop 特有的字段约束
- scoop 自身字段校验逻辑可能随版本演进，用 `scoop cat` 自动跟随

---

## 6. 文件结构

```
scoop-bucket/
├── .github/
│   └── workflows/
│       └── validate-manifests.yml    # CI：push 时校验所有 manifest
├── bucket/                           # 所有 manifest
│   ├── mysql-8.0.21.json
│   ├── openjdk15.json
│   ├── qt-5.6.2-msvc2015-64.json
│   ├── vs2015-cpp.json
│   └── windows10sdk-14393.json
├── scripts/
│   └── install-all.ps1                # 一键按依赖顺序安装全部工具
├── AGENTS.md                          # 本文件 — Agent 维护指南
├── CONTRIBUTING.md                    # 贡献指南（中文）
├── SKILL.md                           # manifest 构建详细参考（中文）
├── README.md                         # 中英双语项目说明
└── LICENSE                           # MIT
```

---

## 7. Agent 维护本项目时的检查清单

每次提交前自检：

- [ ] 如果改了 manifest，是否所有 ✅ 必填字段都在？（version / description / homepage / license / url）
- [ ] 是否新增了 `autoupdate` 或 `checkver` 字段？（必须为没有）
- [ ] JSON 缩进是否 4 空格？
- [ ] 路径反斜杠是否在 JSON 中写成 `\\`？
- [ ] `notes` 字段是否用中文？
- [ ] 如果是新增 manifest，README 的 manifest 表格是否同步更新？
- [ ] 如果改了 README 中文段，英文段是否也同步？
- [ ] 如果 manifest 文件名带版本号，`version` 字段是否与文件名一致？
- [ ] 提交信息是否清晰描述改动？
- [ ] 如果改了 `url`，是否同时考虑了 `hash` 是否需要重算？

---

## 8. 联系与升级路径

- 本项目 Issue：https://github.com/Cikaros/scoop-bucket/issues
- 官方 Scoop 主仓库：https://github.com/ScoopInstaller/Scoop
- 官方 Scoop Wiki：https://github.com/ScoopInstaller/Scoop/wiki

如果本 bucket 上的某个 manifest 与官方 bucket 重叠（例如官方 `versions` bucket 添加了 `mysql-8.0.21`），考虑：
1. 在本 manifest 的 `notes` 里加一行提示用户优先用官方版本
2. 如果用户同意，可以删除本 bucket 的对应 manifest（保留 git 历史可追溯）
