---
name: project-scaffold
description: 在【项目名】中初始化或还原标准项目骨架。当用户要求"初始化项目/搭建目录结构/新建环境/还原工程/补齐配置模板"，或新成员拉取代码后需要确认目录、配置、依赖是否齐全时使用。本 Skill 产出符合本项目四层架构与命名规范的目录、配置模板与依赖清单。
---

# 【项目名】· 项目脚手架与规范初始化

## 1 适用场景

- 新项目从零搭建，需要一次生成标准目录骨架
- 新成员 / 新机器 `git clone` 后需要还原配置与目录
- 新增一个服务或子应用，需要按同一套规范初始化

## 2 前置条件

生成前必须确认（缺少则先向用户询问，不得臆造）：

1. 项目名与坐标（包名前缀，如 `com.example.project`）
2. 技术栈版本（后端框架、前端框架、数据库、缓存、消息）
3. 是否需要多环境配置（dev / test / prod）
4. 数据库迁移工具（Flyway / Liquibase / 无）

## 3 执行步骤

1. 运行 `python scripts/init-project.py --name <名称> --package <包名> --dry-run` 预览将要创建的目录
2. 确认无误后去掉 `--dry-run` 实际执行
3. 按设计说明书 **5.2 源码目录结构** 核对生成结果，四层目录必须齐全
4. 生成 `.env.example`（只放键名与示例值，**禁止真实密钥**）
5. 生成 `README.md` 启动指南，确保评审人 10 分钟内能跑起来
6. 运行 `python scripts/init-project.py --verify` 做结构自检

## 4 本项目强制约束（违反即为错误）

- 后端严格四层：`controller → application → domain → infrastructure`，**单向依赖**
- 目录名全小写，包名全小写；类名大驼峰
- **禁止**把 `node_modules/`、`target/`、`dist/` 等构建产物提交进仓库
- **禁止**任何明文密钥、密码、Token 入库；一律走环境变量或 `.env`（`.env` 必须写进 `.gitignore`）
- 每个环境一份配置，命名 `application-{env}.yml`，默认值只出现在 dev
- 数据库迁移脚本命名 `V{版本}__{描述}.sql`，且必须入库

## 5 输出物

- 四层后端目录 + 前端目录 + `docs/api/` 目录
- `.env.example`、`application-{env}.yml` 模板
- `README.md` 启动指南、`docker-compose.yml` 占位
- 结构自检报告

## 6 自检清单

- [ ] 四层目录齐全且与说明书 5.2 一致
- [ ] `.gitignore` 覆盖构建产物、IDE 配置、`.env`
- [ ] 无明文密钥（可用 `git grep -iE "(password|secret|token)\s*="` 自查）
- [ ] `README.md` 能在 10 分钟内让人把项目跑起来
- [ ] `init-project.py --verify` 通过

## 7 常见错误与反例

**错误 1：把业务逻辑塞进 controller 目录的 util**
```
controller/
├── UserController.java
└── UserUtil.java   ← 业务规则被藏进"工具类"，绕过应用层
```
正确做法：规则下沉到 `domain`，编排放 `application`。

**错误 2：配置里写死数据库密码**
```yaml
spring:
  datasource:
    password: root123   # 错误：明文入库，且会随 Git 历史永久泄露
```
正确做法：`password: ${DB_PASSWORD}`，真实值只放在本地 `.env`。

**错误 3：目录结构与设计文档不一致**
设计文档写的是 `infrastructure/`，代码里却是 `dao/` —— 评审抽查每处扣 2 分。