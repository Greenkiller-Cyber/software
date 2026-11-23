# 03 源码

> 任务书第六章：必须真实前后端分离 + 真实持久化；README 必须让人 **10 分钟内跑起来**。

## 结构

```
03-源码/
├── backend/                       # Spring Boot 单体，四层架构
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/fitmate/
│       │   ├── common/            # 统一响应、错误码、异常处理、健康检查
│       │   └── exercise/          # 模块示例（四层完整落地）
│       │       ├── controller/      # 接入层
│       │       ├── application/     # 应用层
│       │       ├── domain/          # 领域层（无框架注解）
│       │       └── infrastructure/  # 基础设施层（DO / Mapper / Repository 实现）
│       └── resources/
│           ├── application.yml    # 配置，敏感项走环境变量
│           └── db/V1__init.sql    # 建表脚本（与说明书 §4.2 数据字典 1:1）
├── frontend/                      # Vue 3 + Vite（第 9 周起）
├── docs/api/openapi.yaml          # 接口契约
└── docker-compose.yml             # 一键起 MySQL / Redis / RabbitMQ
```

## 启动指南

> 定稿前必须验证：**在一台干净机器上按本文档能在 10 分钟内启动成功**。

### 1 环境要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| JDK | 21（LTS） | 编译与运行；本机验证版本 21.0.10 |
| Maven | 3.9+ | 构建；也可用 IDE 内置 |
| MySQL | 8.0 | 主库，字符集 utf8mb4 |
| Redis | 7 | 缓存（可选，缺失时统计降级查库） |
| RabbitMQ | 3.12 | 异步聚合（可选，缺失时退化为同步） |
| Node.js + pnpm | 18+ / 8+ | 前端（第 9 周起需要） |

### 2 启动步骤

```bash
# 1. 准备环境变量（禁止把 .env 提交入库）
cp .env.example .env

# 2. 启动依赖服务（MySQL / Redis / MQ）
docker compose up -d

# 3. 建库与建表（首次）
mysql -u root -p -e "CREATE DATABASE fitmate DEFAULT CHARSET utf8mb4;"
mysql -u root -p fitmate < backend/src/main/resources/db/V1__init.sql

# 4. 启动后端
cd backend
mvn spring-boot:run
# 或：mvn package && java -jar target/fitmate-backend-0.1.0-SNAPSHOT.jar

# 5. 启动前端（第 9 周起）
cd ../frontend
pnpm install && pnpm dev
```

> 环境变量（`application.yml` 中已给出默认值，可用同名环境变量覆盖）：
> `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` / `SERVER_PORT`

### 3 验证

| 项 | 地址 | 预期 |
|----|------|------|
| 后端健康检查 | `http://localhost:8080/api/v1/health` | `{"code":0,"data":{"status":"UP",...}}` |
| 动作列表 | `http://localhost:8080/api/v1/exercises` | 需数据库就绪，返回动作数组 |
| 前端 | `http://localhost:5173` | 第 9 周起可用 |
| 接口文档 | `03-源码/docs/api/openapi.yaml` | 用 Apifox / Swagger Editor 打开 |

### 4 已实现状态（2026-11-23）

| 能力 | 状态 | 证据 |
|------|------|------|
| 工程可编译 | ✅ | `mvn package` 成功，产出 27MB 可执行 jar |
| 应用可启动 | ✅ | 无数据库时仍可启动，健康检查返回 UP |
| 单元测试 | ✅ | 4 个用例通过（`mvn test`） |
| 建表脚本 | ✅ | `V1__init.sql` 共 19 张表 |
| 动作库接口 | ⚠️ 待数据库 | 代码完成，需 MySQL 起容器后联调 |
| 其余 6 个模块 | ⬜ 未开始 | 按 `exercise` 模板复制 |

### 5 测试账号

| 角色 | 账号 | 密码 |
|------|------|------|
| （待第 10 周初始化种子数据后补充） | — | — |

## 构建备注

- **离线构建**：把依赖仓库指向工作区内目录即可，避免写系统 `~/.m2`：
  `mvn -Dmaven.repo.local=./.m2-repo package`
- 依赖首次下载约 50MB，之后增量。
- `target/` 与 `.m2-repo/` 已在 `.gitignore` 中，不入库。

## 提交前检查

- [ ] 无 `node_modules/`、`target/`、`dist/` 等构建产物入库
- [ ] 无明文密钥（`.env` 已在 `.gitignore`）
- [ ] `docker compose up` 可一键起依赖
- [ ] README 步骤实测可用
- [ ] 单测可一键运行且 ≥10 个用例（当前 4 个，随模块补齐）