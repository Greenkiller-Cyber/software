# 02 开发用 AI Skill 包

> 任务书第五章要求：≥3 个 Skill，每个必须附 `scripts/` 或 `templates/` 中的**至少一项可执行资产**；`usage-log.md` 记录 ≥5 次真实使用并体现迭代反思。

## 1 Skill 清单

| Skill | 解决什么问题 | 附带资产 | 状态 |
|-------|------------|---------|------|
| [`project-scaffold`](project-scaffold/SKILL.md) | 新环境一键还原项目结构与规范 | `scripts/init-project.py` | 骨架完成 |
| [`module-generator`](module-generator/SKILL.md) | 新增业务模块时不破坏分层 | `scripts/check-layering.py`、`templates/` | 脚本可用 |
| [`arch-doc-sync`](arch-doc-sync/SKILL.md) | 代码改了文档没改 → 文档与实现脱节 | `scripts/scan-structure.py` | 脚本可用 |
| `test-and-quality`（加分） | 单测生成与覆盖率门禁 | — | 未开始 |
| `deploy`（加分） | 构建镜像与部署脚本 | — | 未开始 |

## 2 使用方式

1. 把 `SKILL.md` 所在目录加入 AI 工具的 skill / rules 搜索路径；
2. AI 依据 frontmatter 的 `description` 判断是否触发；
3. 触发后按正文「执行步骤」操作，最后按「自检清单」核对，必要时运行 `scripts/` 下的校验脚本。

## 3 关键提醒

- **`description` 是关键的一行**：必须包含用户可能说出的关键词（"新增/创建/添加 XX 模块/接口"），否则 AI 不会调用。
- **Skill 中的规范必须与设计说明书 5.2 / 5.7 完全一致**（任务书：不一致每处 −1 分）。
- 验收标准：把 Skill 给别的组用在他们项目上会生成**错误**代码 —— 说明它足够具体。

## 4 与架构文档的对应关系

| 说明书章节 | 对应的 Skill 约束 |
|-----------|-----------------|
| 3.3 分层与依赖规则 R-01 ~ R-04 | `module-generator` 强制约束 |
| 5.2 源码目录结构 | `project-scaffold`、`arch-doc-sync` |
| 5.7 编码规范 | `module-generator` 强制约束 |
| 5.10 AI 辅助开发方案 | 本 README 的清单 |

## 5 待办

- [ ] 项目选题确定后，统一替换所有 `【项目名】` 占位
- [ ] 按实际技术栈补齐 `templates/` 下的代码模板
- [ ] 用 `scripts/check-layering.py` 对真实代码跑一次，把输出贴进 usage-log
- [ ] 补齐第 4、5 个加分 Skill（可选）