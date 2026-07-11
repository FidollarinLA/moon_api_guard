# OSC 2026 Cursor 交接记录

更新时间：2026-07-11  
本地仓库：`/Users/skyjk/Documents/Moonbit`  
当前状态：还没有任何 git commit，所有项目文件目前都是 untracked。

## 0. 最新状态补充（2026-07-12）

后续查重评估后，当前推荐方向已从 `moon_license_guard` 再次切换为 `moon_api_guard`：MoonBit 公共 API 兼容性与版本守卫工具。公开查重未发现成熟同名或高度相似的 MoonBit 专用 API 兼容性守卫工具；该方向比旧的 `moon_flowgraph` 更贴合工程基础设施、CI 守卫和 mooncakes.io 发布前检查场景。

当前仓库已开始改造为：

```toml
name = "skyjk/moon_api_guard"
```

后文关于 `moon_flowgraph` 和 `moon_license_guard` 的内容保留为历史决策记录，不再代表当前执行方向。

## 1. 当前目标

准备参加 MoonBit 国产基础软件开源大赛 OSC 2026。

章程里最关键的申请要求：

- 项目申报截止：2026-07-12 24:00。
- 申报材料建议控制在一页 PDF。
- 申报内容需要包含项目名称、简介、方向、核心功能、原创/移植说明、GitHub 仓库链接、GitLink 仓库链接。
- GitHub 仓库需要 10-20 个有效 commits，不能靠空提交、无意义拆分或重复提交凑数。
- GitLink 仓库需要和 GitHub 同步。
- 后续验收会看 MoonBit 主体实现、README、CI、测试、可运行示例、开源许可证、mooncakes.io 发布准备等。

## 2. 已完成的环境准备

### OSC 2026 skill

已经安装 `osc2026-guide` skill 到：

```text
/Users/skyjk/.codex/skills/osc2026-guide
```

安装过程：

- 第一轮 git clone 模式卡住。
- 后来用 download 模式安装成功。
- 安装后需要重启 Codex 才会出现在技能列表中。

### MoonBit 工具链

MoonBit 工具链已安装到：

```text
/Users/skyjk/.moon/bin/moon
```

验证结果：

```text
moon 0.1.20260703 (6fbf8c3 2026-07-03)
moonc v0.10.3+16975d007 (2026-07-03)
moonrun 0.1.20260703 (6fbf8c3 2026-07-03)
```

如果 shell 里找不到 `moon`，可以直接用完整路径：

```bash
/Users/skyjk/.moon/bin/moon version --all
```

## 3. 本地仓库当前状态

当前目录：

```text
/Users/skyjk/Documents/Moonbit
```

当前模块仍然是上一次尝试的方向：

```toml
name = "skyjk/moon_flowgraph"
version = "0.1.0"
license = "Apache-2.0"
description = "Workflow and dependency graph analysis helpers for MoonBit."
```

当前主要文件：

```text
moon.mod
moon.pkg
README.mbt.md
README.md -> README.mbt.md
LICENSE
moon_flowgraph.mbt
moon_flowgraph_test.mbt
moon_flowgraph_wbtest.mbt
cmd/main/main.mbt
cmd/main/moon.pkg
.github/workflows/check.yml
OSC2026_申请清单.md
OSC2026_项目申报书.md
OSC2026_报名问卷草稿.md
tools/make_osc2026_proposal_pdf.py
```

当前已有的 `moon_flowgraph` 代码能力：

- `Dependency`
- `FlowGraph`
- 直接前置任务查询
- 直接后续任务查询
- 依赖边存在性查询
- 拓扑排序
- 循环依赖检测
- 依赖解释文本

当前验证通过：

```bash
/Users/skyjk/.moon/bin/moon fmt
/Users/skyjk/.moon/bin/moon check
/Users/skyjk/.moon/bin/moon test
/Users/skyjk/.moon/bin/moon run cmd/main
/Users/skyjk/.moon/bin/moon info
```

其中：

- `moon test` 当前是 5 个测试全部通过。
- `moon run cmd/main` 当前输出：

```text
test waits for build
false
```

注意：这个方向后来发现撞车，不建议继续申报。

## 4. 已尝试过的项目方向和撞车结论

### 4.1 `moon_pathfinding`

最开始拟定方向：

```text
moon_pathfinding：MoonBit 图搜索与寻路算法库
```

计划做：

- 图结构
- BFS / DFS
- Dijkstra
- A*
- 网格地图寻路
- 路径重建

撞车检查结果：风险高。

找到的相近项目：

- `Suquster/moonbit-pathfinding`
  - GitHub: https://github.com/Suquster/moonbit-pathfinding
  - 已经做 MoonBit pathfinding / graph algorithms。
  - 功能包含 BFS、DFS、Dijkstra、A* 等。
  - 和原计划高度重合。
- `hzc-666-ai/MoonPathfinding-MoonBit`
  - GitHub: https://github.com/hzc-666-ai/MoonPathfinding-MoonBit
- `wzx2007/moonpath`
  - GitHub: https://github.com/wzx2007/moonpath

结论：

```text
不要继续用 moon_pathfinding 申报。
```

### 4.2 `moon_flowgraph`

第二次拟定方向：

```text
moon_flowgraph：MoonBit 工作流与依赖图分析库
```

计划做：

- 工作流任务节点
- 依赖边
- 拓扑排序
- 循环依赖检测
- 分层调度
- 诊断说明

撞车检查结果：风险高。

找到的相近项目：

- `AlexenderSokolov/moonflowgraph`
  - GitHub: https://github.com/AlexenderSokolov/moonflowgraph
  - GitLink: https://gitlink.org.cn/SpringBack_25/moonflowgraph
  - 模块名：`AlexenderSokolov/moonflowgraph`
  - 版本：`0.2.0`
  - 描述：MoonBit task graph and provenance trace library。
  - 已经包含 task graph、dependency edges、cycle detection、topological order、parallel execution batches、workflow CLI、JSON import/export、Mermaid export、trace/provenance events。

结论：

```text
不要继续用 moon_flowgraph 申报。
```

### 4.3 `moon_pkg_audit`

第三次考虑方向：

```text
moon_pkg_audit：MoonBit 包发布前自检工具
```

设想检查：

- README
- LICENSE
- `moon.mod`
- `pkg.generated.mbti`
- CI
- 示例
- 发布准备

撞车检查结果：中高风险。

找到的相近项目：

- `gywcs101/MoonDocCheck`
  - GitHub: https://github.com/gywcs101/MoonDocCheck
  - 模块名：`gywcs101/MoonDocCheck`
  - 描述：MoonBit documentation quality checker for open-source packages and contest submissions。
  - 功能包括 README 检查、API 文档注释检查、`moon.mod` 元数据检查、`pkg.generated.mbti` 检查、CI 信号检查、本地目录和 GitHub 仓库扫描、text/HTML/Markdown/JSON 报告。

结论：

```text
不要做泛泛的 moon_pkg_audit，容易和 MoonDocCheck 重合。
```

## 5. 当前最推荐的新方向

建议改成：

```text
moon_license_guard：MoonBit 开源许可证与来源合规检查工具
```

这个方向比 `moon_pkg_audit` 更窄，和 `MoonDocCheck` 区分更明显。

### 项目定位

`moon_license_guard` 是一个面向 MoonBit 开源项目的许可证与第三方来源合规检查工具。它帮助开发者在发布、参赛、课程提交或社区评审前检查项目是否说明清楚：

- 根目录是否有开源许可证。
- `moon.mod` 里的 license 字段是否存在并和根目录许可证一致。
- README 是否说明许可证。
- 如果项目是移植/参考已有开源项目，是否写明原项目名称、链接、许可证和参考范围。
- 是否存在复制代码、生成代码、测试数据、样例文件，但没有说明来源。
- 是否有 `NOTICE`、`THIRD_PARTY.md`、`ATTRIBUTION.md` 等第三方来源说明文件。
- 是否能生成一份 Markdown/JSON 合规报告。

### 为什么适合比赛

比赛章程很重视：

- OSI 认可开源许可证。
- 参考或移植项目必须说明原项目名称、链接、许可证和参考范围。
- 不得侵犯知识产权。
- 测试数据、样例文件、生成代码要保证来源合法合规。

所以 `moon_license_guard` 和赛事要求直接相关。

### 和 MoonDocCheck 的区别

`MoonDocCheck` 偏文档成熟度、README、API 注释、CI、报告。

`moon_license_guard` 应该聚焦合规，不做泛文档质量评分：

- 许可证一致性。
- 第三方来源披露。
- 生成代码和测试数据来源。
- 移植项目合规说明。
- 风险等级和修复建议。

## 6. 建议在 Cursor 中的下一步操作

### 第一步：保留仓库，整体改名和改方向

把当前 `moon_flowgraph` 改成 `moon_license_guard`。

需要改这些文件：

```text
moon.mod
README.mbt.md
cmd/main/moon.pkg
cmd/main/main.mbt
moon_flowgraph.mbt -> moon_license_guard.mbt
moon_flowgraph_test.mbt -> moon_license_guard_test.mbt
moon_flowgraph_wbtest.mbt -> moon_license_guard_wbtest.mbt
pkg.generated.mbti
cmd/main/pkg.generated.mbti
OSC2026_项目申报书.md
OSC2026_报名问卷草稿.md
OSC2026_申请清单.md
tools/make_osc2026_proposal_pdf.py
```

`moon.mod` 建议改成：

```toml
name = "skyjk/moon_license_guard"
version = "0.1.0"
readme = "README.md"
repository = ""
license = "Apache-2.0"
keywords = [
  "license",
  "compliance",
  "open-source",
  "moonbit",
  "audit",
]
preferred_target = "wasm-gc"
description = "License and source attribution checks for MoonBit projects."
```

### 第二步：做第一版最小实现

建议第一版只做静态字符串/文件名级别检查，不要一开始就做复杂解析。

可以先实现这些类型：

```moonbit
pub(all) enum Severity {
  Info
  Warning
  Error
} derive(Eq, Debug)

pub(all) struct AuditIssue {
  code : String
  severity : Severity
  message : String
} derive(Eq, Debug)

pub(all) struct ProjectSignals {
  has_license_file : Bool
  moon_mod_license : String?
  readme_mentions_license : Bool
  has_third_party_notice : Bool
  mentions_generated_code : Bool
  mentions_test_data_source : Bool
} derive(Debug)
```

第一批函数可以是：

```moonbit
pub fn check_license_presence(signals : ProjectSignals) -> Array[AuditIssue]
pub fn check_license_consistency(signals : ProjectSignals) -> Array[AuditIssue]
pub fn check_attribution_notes(signals : ProjectSignals) -> Array[AuditIssue]
pub fn audit_project_signals(signals : ProjectSignals) -> Array[AuditIssue]
pub fn issue_count_by_severity(issues : Array[AuditIssue], severity : Severity) -> Int
```

第一版测试场景：

- 有 LICENSE 且 moon.mod license 一致：无 Error。
- 缺 LICENSE：Error。
- moon.mod license 空：Warning 或 Error。
- README 没提 license：Warning。
- 有第三方来源但无 attribution：Error。
- 生成代码/测试数据未说明来源：Warning 或 Error。

### 第三步：补 CLI 示例

`cmd/main/main.mbt` 可以先输出一个模拟审计结果，例如：

```text
moon_license_guard report
errors: 0
warnings: 1
```

后续再做真正读取本地文件。

### 第四步：跑本地验证

每次修改后跑：

```bash
/Users/skyjk/.moon/bin/moon fmt
/Users/skyjk/.moon/bin/moon check
/Users/skyjk/.moon/bin/moon test
/Users/skyjk/.moon/bin/moon run cmd/main
/Users/skyjk/.moon/bin/moon info
```

### 第五步：形成 10-20 个有效 commits

现在还没有 commit。比赛要求 GitHub 仓库有 10-20 个有效 commits。

建议 commit 拆法：

1. `Initialize MoonBit project scaffold`
2. `Add license guard project metadata`
3. `Define audit issue and severity types`
4. `Add project signal model`
5. `Check root license presence`
6. `Check moon.mod license metadata`
7. `Check license consistency`
8. `Add attribution and third-party source checks`
9. `Add generated code and test data source checks`
10. `Add CLI demo output`
11. `Document usage and contest scope`
12. `Add CI workflow`
13. `Add OSC 2026 proposal materials`

注意：不要空提交，不要只改空格凑数。

## 7. 当前已有的申请材料

这些文件已经存在，但内容目前还是 `moon_flowgraph`，需要改成 `moon_license_guard` 后才能提交：

```text
OSC2026_申请清单.md
OSC2026_项目申报书.md
OSC2026_报名问卷草稿.md
output/pdf/OSC2026_moon_flowgraph_项目申报书.pdf
```

PDF 生成脚本：

```text
tools/make_osc2026_proposal_pdf.py
```

生成 PDF 命令：

```bash
/Users/skyjk/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/make_osc2026_proposal_pdf.py
```

注意：`output/` 和 `tmp/` 已经在 `.gitignore` 中，PDF 默认不会进入 git。

## 8. 最后需要提交申请时的清单

正式提交前必须准备：

- 真实参赛者姓名或昵称。
- 联系方式。
- GitHub 公开仓库链接。
- GitLink 同步仓库链接。
- 一页 PDF 或 Markdown 申报书。
- 10-20 个有效 commits。
- README、LICENSE、示例、测试、CI。
- `moon check` / `moon test` 本地通过。

建议最终仓库名：

```text
moon_license_guard
```

建议 GitHub 仓库：

```text
https://github.com/<你的 GitHub 用户名>/moon_license_guard
```

建议 GitLink 仓库：

```text
从 GitHub 导入同名项目，并确认默认分支同步。
```

## 9. Cursor 可以直接使用的提示词

可以把下面这段粘给 Cursor：

```text
请阅读 CURSOR_HANDOFF_OSC2026.md。当前仓库仍是 moon_flowgraph，但该方向已撞车，不要继续。请将项目整体重构为 moon_license_guard：一个 MoonBit 开源许可证与第三方来源合规检查工具。保留 MoonBit 项目骨架和 CI，但重命名模块、源码、测试、README、申报材料和 PDF 生成脚本。第一版实现 ProjectSignals、Severity、AuditIssue，以及许可证存在性、moon.mod license、一致性、第三方来源说明、生成代码/测试数据来源等检查。每个功能对应测试。最后运行 moon fmt、moon check、moon test、moon run cmd/main、moon info，确保全部通过。
```

