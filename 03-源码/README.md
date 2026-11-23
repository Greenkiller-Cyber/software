# 03 源码

> 任务书第六章：必须真实前后端分离 + 真实持久化；README 必须让人 **10 分钟内跑起来**。

## 结构

```
03-源码/
├── backend/            # 后端（四层架构）
│   └── src/main/java/<包名>/
│       ├── controller/       # 接入层
│       ├── application/      # 应用层
│       ├── domain/           # 领域层
│       └── infrastructure/   # 基础设施层
├── frontend/           # 前端
├── docs/api/openapi.yaml     # 接口契约（覆盖 ≥80% 接口）
└── docker-compose.yml        # 一键启动
```

## 启动指南（待补全）

> 定稿前必须验证：**在一台干净机器上按本文档能在 10 分钟内启动成功**。

### 1 环境要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| JDK | 【待填写】 | |
| Node.js | 【待填写】 | |
| Docker | 【待填写】 | 推荐用 compose 起中间件 |

### 2 启动步骤

```bash
# 1. 准备环境变量
cp .env.example .env      # 填入数据库密码等，禁止提交 .env

# 2. 启动依赖服务（MySQL / Redis / MQ）
docker compose up -d

# 3. 启动后端
# 【待填写】

# 4. 启动前端
# 【待填写】
```

### 3 验证

- 后端健康检查：【待填写，如 http://localhost:8080/actuator/health】
- 前端地址：【待填写，如 http://localhost:5173】
- 接口文档：【待填写，如 http://localhost:8080/swagger-ui.html】

### 4 测试账号

| 角色 | 账号 | 密码 |
|------|------|------|
| | | |

## 提交前检查

- [ ] 无 `node_modules/`、`target/`、`dist/` 等构建产物入库
- [ ] 无明文密钥（`.env` 已在 `.gitignore`）
- [ ] `docker compose up` 可一键起依赖
- [ ] README 步骤实测可用
- [ ] 单测可一键运行且 ≥10 个用例