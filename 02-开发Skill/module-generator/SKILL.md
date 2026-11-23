---
name: module-generator
description: 在【项目名】中按四层架构生成新的业务模块。当用户要求"新增/创建/添加 XX 功能、模块、接口"，或需要生成 Controller、Service、Repository、DTO、数据库迁移脚本、单元测试时使用。生成代码严格遵守 controller→application→domain←infrastructure 单向依赖，统一返回 Result<T>。
---

# 【项目名】· 业务模块生成器

## 1 适用场景

- 新增一个业务模块（如"优惠券""评论""通知"）
- 为已有模块补充接口
- 生成对应的数据库迁移脚本与单元测试

## 2 前置条件

生成前必须确认（缺少则先向用户询问，不得臆造）：

1. 模块名（大驼峰，如 `Coupon`）、所属限界上下文
2. 涉及的领域实体与关键字段
3. 接口清单（方法、路径、请求/响应字段）
4. 是否涉及状态流转（若涉及，先确认状态枚举与迁移规则）
5. 是否涉及权限（哪个角色可以调用）

## 3 执行步骤

1. 在 `docs/api/openapi.yaml` 中登记接口定义（**先写契约，后写代码**）
2. 按 `templates/` 生成四层代码骨架
3. 逐层填写：
   - `XxxController`：仅参数校验与路由，**不写业务逻辑**
   - `XxxApplicationService`：用例编排，事务边界标注在此
   - `Xxx`（领域实体 / 领域服务）：纯业务规则，不依赖框架
   - `XxxRepository`：接口定义在 domain 层，实现在 infrastructure 层
4. 生成数据库迁移脚本 `V{版本}__{描述}.sql`
5. 运行 `python scripts/check-layering.py <代码根目录>` 校验依赖方向
6. 生成单元测试（正常流程 + 边界 + 异常，≥3 个用例）
7. 回填 `docs/api/openapi.yaml` 的实现说明，更新设计说明书 §3.1 模块树

## 4 本项目强制约束（违反即为错误）

- **禁止** Controller 直接调用 Repository，必须经过 ApplicationService
- **禁止** domain 层出现 Spring / MyBatis / Servlet 等框架注解（`import org.springframework.*` 一律不允许）
- **禁止** infrastructure 层反向依赖 application 层
- **禁止** 同层之间横向调用（规则 R-03）
- 所有对外接口统一返回 `Result<T>`，业务异常抛 `BizException`，由 `GlobalExceptionHandler` 转换
- `@Transactional` 只能标注在 application 层 public 方法上
- 日志用 `@Slf4j`，禁止 `System.out.println`，禁止打印密码 / 手机号
- 金额用 `BigDecimal`（禁止 `double`）；时间用 `LocalDateTime`（禁止 `Date`）
- 所有列表查询必须分页，禁止无条件全表查询

## 5 输出物

- `XxxController.java`、`XxxApplicationService.java`、`Xxx.java`、`XxxRepository.java`（+ Impl）
- `XxxRequest.java` / `XxxResponse.java` DTO
- `V{版本}__create_xxx.sql`
- `XxxApplicationServiceTest.java`
- OpenAPI 增量片段

## 6 自检清单

- [ ] 依赖方向无反向引用（`check-layering.py` 通过）
- [ ] domain 层无框架 import
- [ ] 每个 public 方法有 Javadoc
- [ ] 无硬编码密钥、无魔法值（常量已提取）
- [ ] 接口已登记到 `docs/api/openapi.yaml`
- [ ] `mvn verify` 通过，覆盖率未下降

## 7 常见错误与反例

**错误 1：Controller 里写业务逻辑**

```java
// 错误
@PostMapping("/coupon")
public Result<Long> create(@RequestBody CouponReq req) {
    if (req.getTitle().length() > 50) throw new BizException("标题过长");
    Coupon c = couponRepository.save(convert(req));   // 直接调 Repository
    return Result.ok(c.getId());
}
```

```java
// 正确
@PostMapping("/coupon")
public Result<Long> create(@Valid @RequestBody CouponReq req) {
    return Result.ok(couponApplicationService.create(req));
}
```

**错误 2：事务边界放在 Controller 或 Repository**
事务必须与应用层用例对齐，否则长事务拖垮连接池。

**错误 3：domain 层引入框架**
领域实体一旦依赖 Spring，就无法脱离容器做单元测试，分层也就名存实亡。

**错误 4：Repository 接口写在 infrastructure 层**
接口应在 domain（依赖抽象），实现才在 infrastructure（依赖倒置）。