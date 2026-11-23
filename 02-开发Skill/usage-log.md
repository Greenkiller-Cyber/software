# Skill 使用记录（usage-log）

> 任务书 5.2：**≥5 次真实使用**，每次包含"日期 / 场景 / AI 生成了什么 / 我修改了什么 / 为什么"，并体现「发现问题 → 改进 Skill」的迭代闭环。
> 罗列流水账不算分（该项 0 分）；本条要求占 8 分中的 2 分。

## 记录总表

| 序号 | 日期 | 场景 | 使用的 Skill | AI 产出是否有问题 | 是否回头改了 Skill |
|------|------|------|------------|-----------------|------------------|
| 1 | 2026-11-23 | 搭建后端工程骨架与四层目录 | project-scaffold | 是（PowerShell 脚本被策略拦截） | 是（改写为 Python） |
| 2 | 2026-11-23 | 新增首个业务模块 exercise | module-generator | 是（DO 与领域对象混在一起） | 是（补强制约束） |
| 3 | 2026-11-23 | 用分层校验脚本检查真实代码 | module-generator | 是（脚本把框架 import 误判为同层依赖） | 是（修正判定逻辑） |
| 4 | | | | | |
| 5 | | | | | |

---

## 2026-11-23　后端工程骨架初始化

- **场景**：需要从零生成一个 Spring Boot 四层工程骨架（12 个目录、`.env.example`、包名 `com.fitmate`）。
- **使用的 Skill**：project-scaffold
- **AI 初次产出**：生成了 `init-project.ps1`，用 PowerShell 建目录并写模板文件。
- **我的修正**：
  1. 本机执行策略禁止运行 `.ps1`（`PSSecurityException`），改为 Python 脚本 `init-project.py`；
  2. 同步更新 SKILL.md、`02-开发Skill/README.md` 与根 README 中的调用示例；
  3. 补 `--dry-run` 与 `--verify` 两个开关，先看将创建什么再落盘。
- **为什么**：Skill 的产出必须能在**目标机器**上直接跑通。环境相关的能力（脚本语言）不能想当然，
  否则"自动化"反而变成一次额外排障。
- **对 Skill 的改进**：「前置检查」增加一条——Windows 下不依赖 `.ps1`，统一用 Python；
  并在「常见错误」记录执行策略拦截这一坑。

---

## 2026-11-23　新增 exercise 模块（动作库）

- **场景**：新增第一个业务模块：Controller + ApplicationService + Repository + DO + Mapper + 单测。
- **使用的 Skill**：module-generator
- **AI 初次产出**：生成了一个 `Exercise` 类，直接用 MyBatis-Plus 的 `@TableName` / `@TableId` 注解，
  并在 Service 里注入 Mapper 直接查询。
- **我的修正**：
  1. 拆成两层：`domain.Exercise`（纯 record，无任何框架注解）+ `infrastructure.persistence.ExerciseDO`（带 MP 注解）；
  2. Repository 接口放 `domain`（端口），实现放 `infrastructure`（适配器），Service 只依赖接口；
  3. Service 里加 `@Transactional(readOnly = true)`，明确只读事务边界。
- **为什么**：若领域对象带 `@TableName`，`domain` 层就依赖了 ORM 框架，R-02 直接破功；
  后续换持久化方案（如换 JDBC）时领域代码全要改。**依赖倒置的收益在换实现时才体现**，
  但违反它的成本在第一天就埋下了。
- **对 Skill 的改进**：在「强制约束」补第 5 条"领域对象禁止出现任何持久化注解"，
  并把 DO/领域对象分离写进模板（生成时直接产出两个类）。

---

## 2026-11-23　用 check-layering.py 校验真实代码（发现脚本自身缺陷）

- **场景**：骨架代码写完后，用 Skill 自带的分层校验脚本检查是否符合 R-01~R-04。
- **使用的 Skill**：module-generator（附带 `scripts/check-layering.py`）
- **AI 初次产出**：脚本报出 3 处"违规"，全部是误报：
  - `import org.springframework.stereotype.Service` → 被判为"application 依赖 application"
  - `import org.apache.ibatis.annotations.Mapper` → 被判为"infrastructure 依赖 infrastructure"
  - `import org.springframework.stereotype.Repository` → 同上
- **我的修正**：
  1. 定位根因：`target_layer()` 取 import 的**末段**匹配层名，而 `Service` / `Mapper` / `Repository`
     恰好是框架类的名字，被当成了本项目分层；
  2. 改为**只有 `base-package` 前缀内的 import 才参与层间判定**，第三方包单独走 `FORBIDDEN_IMPORT` 黑名单；
  3. 同时把"同层内部引用"加入白名单（一个层当然可以引用自己的类）；
  4. 反向验证：故意在 `domain` 放一个 `@Component` 类，脚本能准确报出 R-02 违规，说明修复没有把检查能力削弱。
- **为什么**：**校验工具自身的假阳性比不检查更有害**——它会训练人"看到红字就忽略"，
  最终真正的违规也被无视。这条修正的价值不在代码，而在保住校验的可信度。
- **对 Skill 的改进**：在 SKILL.md 的「自检」章节注明"脚本对第三方 import 不判定层间依赖"，
  并把这条写进 `arch-doc-sync` 的联动说明（文档-代码一致性检查同样只认项目内引用）。

---

## 写作提醒

- 每一条都要有**"我的修正"**和**"为什么"**，这是评分关注点
- 同一条 Skill 被用多次时，记录 **Skill 版本前后的差异**（体现迭代）
- 可附上 `check-layering.py` 的实际输出作为"校验生效"的证据