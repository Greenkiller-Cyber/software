-- =====================================================================
-- FitMate 训练计划与执行管理  —— 初始化建表脚本
-- 版本：V1
-- 字符集：utf8mb4 / utf8mb4_0900_ai_ci
-- 说明：本脚本与《架构设计说明书》§4.2 数据字典必须逐字段一致。
--       文档中标注的表名、字段名、类型、约束均以此脚本为准。
-- 执行：mysql -u root -p fitmate < V1__init.sql
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------
-- 1 账号
-- ---------------------------------------------------------------
CREATE TABLE t_user (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    nickname        VARCHAR(32)     NOT NULL                COMMENT '昵称，展示用',
    phone_cipher    VARCHAR(128)    NOT NULL                COMMENT '手机号密文（AES-GCM，随机 IV）',
    phone_hash      CHAR(64)        NOT NULL                COMMENT '手机号哈希（用于唯一查询，避免密文不可比）',
    password_hash   VARCHAR(100)    NOT NULL                COMMENT 'BCrypt(cost=10) 加盐哈希',
    role            ENUM('MEMBER','COACH','ADMIN') NOT NULL DEFAULT 'MEMBER' COMMENT '角色基线',
    status          TINYINT         NOT NULL DEFAULT 1      COMMENT '1 正常 / 0 禁用 / 2 注销待清理',
    last_login_at   DATETIME        NULL                    COMMENT '最后登录时间',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted         TINYINT         NOT NULL DEFAULT 0      COMMENT '逻辑删除：0 未删 / 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_phone_hash (phone_hash),
    KEY idx_role_status (role, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- ---------------------------------------------------------------
-- 2 健身者档案
-- ---------------------------------------------------------------
CREATE TABLE t_member_profile (
    member_id           BIGINT UNSIGNED NOT NULL            COMMENT '主键，对应用户',
    height_cm           DECIMAL(5,1)    NULL                COMMENT '身高 cm',
    weight_kg           DECIMAL(5,1)    NULL                COMMENT '体重 kg',
    body_fat_pct        DECIMAL(4,1)    NULL                COMMENT '体脂率 %，可空',
    training_years      DECIMAL(3,1)    NOT NULL DEFAULT 0  COMMENT '训练年限，决定强度档位',
    goal                ENUM('HYPERTROPHY','FAT_LOSS','TONE','STRENGTH') NOT NULL COMMENT '训练目标',
    equipment_mask      INT UNSIGNED    NOT NULL DEFAULT 0  COMMENT '器械位掩码：1 杠铃/2 哑铃/4 器械/8 弹力带/16 徒手',
    coach_visible_scope ENUM('NONE','SUMMARY','DETAIL') NOT NULL DEFAULT 'NONE' COMMENT '默认对教练的可见范围',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted             TINYINT         NOT NULL DEFAULT 0,
    PRIMARY KEY (member_id),
    CONSTRAINT fk_profile_user FOREIGN KEY (member_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='健身者档案';

-- ---------------------------------------------------------------
-- 3 教练
-- ---------------------------------------------------------------
CREATE TABLE t_coach (
    coach_id        BIGINT UNSIGNED NOT NULL                COMMENT '主键，对应用户',
    real_name       VARCHAR(32)     NOT NULL                COMMENT '真实姓名',
    certifications  VARCHAR(255)    NULL                    COMMENT '资质证明（文本或文件 URL）',
    years           TINYINT UNSIGNED NOT NULL DEFAULT 0     COMMENT '从业年限',
    intro           VARCHAR(500)    NULL                    COMMENT '简介',
    status          ENUM('PENDING','ACTIVE','REJECTED','SUSPENDED') NOT NULL DEFAULT 'PENDING' COMMENT '资质审核状态',
    audit_task_id   BIGINT UNSIGNED NULL                    COMMENT '关联审核工单',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         TINYINT         NOT NULL DEFAULT 0,
    PRIMARY KEY (coach_id),
    KEY idx_status (status),
    CONSTRAINT fk_coach_user FOREIGN KEY (coach_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='教练';

-- ---------------------------------------------------------------
-- 4 学员-教练授权关系（核心领域对象）
-- ---------------------------------------------------------------
CREATE TABLE t_coach_authorization (
    id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    member_id        BIGINT UNSIGNED NOT NULL                COMMENT '授权方（学员）',
    coach_id         BIGINT UNSIGNED NOT NULL                COMMENT '被授权方（教练）',
    scope            ENUM('SUMMARY','DETAIL') NOT NULL DEFAULT 'SUMMARY' COMMENT '可见范围',
    expire_at        DATETIME        NOT NULL                COMMENT '到期时间，过期即失效',
    status           ENUM('ACTIVE','REVOKED','EXPIRED') NOT NULL DEFAULT 'ACTIVE' COMMENT '状态',
    revoked_at       DATETIME        NULL                    COMMENT '收回时间',
    -- 同一对 (学员, 教练) 只允许一条 ACTIVE 记录；用生成列 + 唯一索引实现
    -- （MySQL 8 无部分索引，ACTIVE 之外的行生成列为 NULL，不参与唯一性）
    active_member_id BIGINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN status = 'ACTIVE' THEN member_id ELSE NULL END) STORED COMMENT '活跃授权：学员',
    active_coach_id  BIGINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN status = 'ACTIVE' THEN coach_id ELSE NULL END) STORED COMMENT '活跃授权：教练',
    created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_active_pair (active_member_id, active_coach_id),
    KEY idx_member_status (member_id, status),
    KEY idx_coach_status (coach_id, status, expire_at),
    CONSTRAINT fk_auth_member FOREIGN KEY (member_id) REFERENCES t_user (id),
    CONSTRAINT fk_auth_coach  FOREIGN KEY (coach_id)  REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学员-教练授权关系';

-- ---------------------------------------------------------------
-- 5 动作库
-- ---------------------------------------------------------------
CREATE TABLE t_exercise (
    id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    name          VARCHAR(64)     NOT NULL                COMMENT '动作名',
    muscle_group  ENUM('CHEST','BACK','LEGS','SHOULDER','ARMS','CORE') NOT NULL COMMENT '主肌群',
    equipment     ENUM('BARBELL','DUMBBELL','MACHINE','BAND','BODYWEIGHT') NOT NULL COMMENT '所需器械',
    difficulty    TINYINT UNSIGNED NOT NULL DEFAULT 2     COMMENT '难度 1-4，新手过滤',
    demo_url      VARCHAR(255)    NULL                    COMMENT '示范素材地址',
    tips          VARCHAR(500)    NULL                    COMMENT '动作要领',
    status        TINYINT         NOT NULL DEFAULT 1      COMMENT '1 启用 / 0 停用',
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted       TINYINT         NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_name (name),
    KEY idx_group_equipment (muscle_group, equipment, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='动作库';

-- ---------------------------------------------------------------
-- 6 训练模板
-- ---------------------------------------------------------------
CREATE TABLE t_template (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    owner_id        BIGINT UNSIGNED NOT NULL                COMMENT '创建者（教练/用户）',
    name            VARCHAR(64)     NOT NULL                COMMENT '模板名',
    goal            ENUM('HYPERTROPHY','FAT_LOSS','TONE','STRENGTH') NOT NULL COMMENT '适配目标',
    days_per_week   TINYINT UNSIGNED NOT NULL DEFAULT 3     COMMENT '每周训练天数',
    status          ENUM('DRAFT','PENDING','APPROVED','REJECTED','PUBLISHED','OFFLINE') NOT NULL DEFAULT 'DRAFT' COMMENT '审核流状态',
    version         INT UNSIGNED    NOT NULL DEFAULT 1      COMMENT '版本号，驳回重提 +1',
    audit_task_id   BIGINT UNSIGNED NULL                    COMMENT '当前审核工单',
    published_at    DATETIME        NULL                    COMMENT '上架时间',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         TINYINT         NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_owner (owner_id),
    KEY idx_status_published (status, published_at),
    CONSTRAINT fk_template_owner FOREIGN KEY (owner_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='训练模板';

-- ---------------------------------------------------------------
-- 7 模板动作项
-- ---------------------------------------------------------------
CREATE TABLE t_template_item (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    template_id  BIGINT UNSIGNED NOT NULL                COMMENT '所属模板',
    day_index    TINYINT UNSIGNED NOT NULL               COMMENT '第几个训练日',
    order_no     TINYINT UNSIGNED NOT NULL               COMMENT '当日顺序',
    exercise_id  BIGINT UNSIGNED NOT NULL                COMMENT '动作',
    sets         TINYINT UNSIGNED NOT NULL               COMMENT '组数',
    reps         TINYINT UNSIGNED NOT NULL               COMMENT '次数',
    rest_sec     SMALLINT UNSIGNED NOT NULL DEFAULT 90   COMMENT '组间休息秒',
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_day_order (template_id, day_index, order_no),
    KEY idx_exercise (exercise_id),
    CONSTRAINT fk_item_template FOREIGN KEY (template_id) REFERENCES t_template (id) ON DELETE CASCADE,
    CONSTRAINT fk_item_exercise FOREIGN KEY (exercise_id) REFERENCES t_exercise (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='模板动作项';

-- ---------------------------------------------------------------
-- 8 计划实例（含模板快照）
-- ---------------------------------------------------------------
CREATE TABLE t_plan (
    id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    member_id          BIGINT UNSIGNED NOT NULL                COMMENT '持有者',
    source_template_id BIGINT UNSIGNED NULL                    COMMENT '来源模板（仅溯源，不用于渲染）',
    snapshot_json      JSON            NOT NULL                COMMENT '生成时的结构快照，模板下架不影响历史',
    goal               ENUM('HYPERTROPHY','FAT_LOSS','TONE','STRENGTH') NOT NULL COMMENT '生成时的目标',
    start_date         DATE            NOT NULL                COMMENT '周期起始日',
    total_weeks        TINYINT UNSIGNED NOT NULL DEFAULT 4     COMMENT '周期长度',
    current_week       TINYINT UNSIGNED NOT NULL DEFAULT 1     COMMENT '当前周次',
    status             ENUM('DRAFT','ACTIVE','COMPLETED','ABORTED') NOT NULL DEFAULT 'DRAFT' COMMENT '计划生命周期',
    -- 同一用户只允许一个进行中计划（生成列 + 唯一索引，NULL 不参与唯一性）
    active_member_id   BIGINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN status = 'ACTIVE' THEN member_id ELSE NULL END) STORED COMMENT '进行中计划的用户',
    created_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted            TINYINT         NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_active_plan (active_member_id),
    KEY idx_member_start (member_id, start_date),
    CONSTRAINT fk_plan_member   FOREIGN KEY (member_id) REFERENCES t_user (id),
    CONSTRAINT fk_plan_template FOREIGN KEY (source_template_id) REFERENCES t_template (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计划实例';

-- ---------------------------------------------------------------
-- 9 计划训练日
-- ---------------------------------------------------------------
CREATE TABLE t_plan_day (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    plan_id     BIGINT UNSIGNED NOT NULL                COMMENT '所属计划',
    week_index  TINYINT UNSIGNED NOT NULL               COMMENT '第几周 1-4',
    day_index   TINYINT UNSIGNED NOT NULL               COMMENT '本周第几练',
    plan_date   DATE            NULL                    COMMENT '计划日期，激活时推算',
    focus       VARCHAR(64)     NULL                    COMMENT '训练重点',
    status      ENUM('PENDING','DONE','SKIPPED') NOT NULL DEFAULT 'PENDING' COMMENT '训练日状态',
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_plan_week_day (plan_id, week_index, day_index),
    KEY idx_plan_date (plan_id, plan_date),
    CONSTRAINT fk_day_plan FOREIGN KEY (plan_id) REFERENCES t_plan (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计划训练日';

-- ---------------------------------------------------------------
-- 10 训练会话
-- ---------------------------------------------------------------
CREATE TABLE t_workout_session (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    plan_day_id  BIGINT UNSIGNED NULL                    COMMENT '关联训练日，自由训练可空',
    member_id    BIGINT UNSIGNED NOT NULL                COMMENT '训练者',
    started_at   DATETIME        NOT NULL                COMMENT '开始时间',
    finished_at  DATETIME        NULL                    COMMENT '结束时间',
    duration_sec INT UNSIGNED    NULL                    COMMENT '时长（秒）',
    status       ENUM('ONGOING','FINISHED','ABANDONED') NOT NULL DEFAULT 'ONGOING' COMMENT '会话状态',
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_member_started (member_id, started_at),
    KEY idx_plan_day (plan_day_id),
    CONSTRAINT fk_session_member FOREIGN KEY (member_id) REFERENCES t_user (id),
    CONSTRAINT fk_session_day    FOREIGN KEY (plan_day_id) REFERENCES t_plan_day (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='训练会话';

-- ---------------------------------------------------------------
-- 11 组次记录（最细粒度事实表）
-- ---------------------------------------------------------------
CREATE TABLE t_set_record (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    session_id   BIGINT UNSIGNED NOT NULL                COMMENT '所属会话',
    exercise_id  BIGINT UNSIGNED NOT NULL                COMMENT '动作',
    set_index    TINYINT UNSIGNED NOT NULL               COMMENT '第几组，从 1 开始',
    weight_kg    DECIMAL(6,2)    NOT NULL DEFAULT 0      COMMENT '重量 kg，自重记 0',
    reps         SMALLINT UNSIGNED NOT NULL              COMMENT '次数',
    rpe          TINYINT UNSIGNED NULL                   COMMENT '主观强度 1-10，可空',
    client_token VARCHAR(64)     NOT NULL                COMMENT '客户端幂等键',
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_client_token (client_token),
    KEY idx_session (session_id),
    KEY idx_exercise (exercise_id),
    CONSTRAINT ck_rpe CHECK (rpe IS NULL OR (rpe BETWEEN 1 AND 10)),
    CONSTRAINT fk_set_session  FOREIGN KEY (session_id) REFERENCES t_workout_session (id) ON DELETE CASCADE,
    CONSTRAINT fk_set_exercise FOREIGN KEY (exercise_id) REFERENCES t_exercise (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='组次记录';

-- ---------------------------------------------------------------
-- 12 日聚合统计
-- ---------------------------------------------------------------
CREATE TABLE t_daily_stat (
    member_id    BIGINT UNSIGNED NOT NULL            COMMENT '用户',
    stat_date    DATE            NOT NULL            COMMENT '统计日',
    tonnage      DECIMAL(12,2)   NOT NULL DEFAULT 0  COMMENT '当日容量 Σ(重量×次数)',
    sets         INT UNSIGNED    NOT NULL DEFAULT 0  COMMENT '当日总组数',
    sessions     INT UNSIGNED    NOT NULL DEFAULT 0  COMMENT '当日会话数',
    duration_sec INT UNSIGNED    NOT NULL DEFAULT 0  COMMENT '当日总时长',
    updated_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (member_id, stat_date),
    CONSTRAINT fk_stat_member FOREIGN KEY (member_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日聚合统计';

-- ---------------------------------------------------------------
-- 13 审核工单
-- ---------------------------------------------------------------
CREATE TABLE t_audit_task (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    target_type  ENUM('TEMPLATE','COACH') NOT NULL       COMMENT '审核对象类型',
    target_id    BIGINT UNSIGNED NOT NULL                COMMENT '对象 ID',
    status       ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING' COMMENT '工单状态',
    reviewer_id  BIGINT UNSIGNED NULL                    COMMENT '审核人（管理员）',
    comment      VARCHAR(500)    NULL                    COMMENT '审核意见，驳回必填',
    submitted_at DATETIME        NOT NULL                COMMENT '提交时间',
    decided_at   DATETIME        NULL                    COMMENT '处理时间',
    version      INT UNSIGNED    NOT NULL DEFAULT 0      COMMENT '乐观锁版本',
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_status_submitted (status, submitted_at),
    KEY idx_target (target_type, target_id),
    CONSTRAINT fk_audit_reviewer FOREIGN KEY (reviewer_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审核工单';

-- ---------------------------------------------------------------
-- 14 周报快照
-- ---------------------------------------------------------------
CREATE TABLE t_weekly_report (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    member_id    BIGINT UNSIGNED NOT NULL                COMMENT '用户',
    week_start   DATE            NOT NULL                COMMENT '周一日期',
    payload_json JSON            NOT NULL                COMMENT '周报内容快照',
    generated_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_week (member_id, week_start),
    CONSTRAINT fk_report_member FOREIGN KEY (member_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='周报快照';

-- ---------------------------------------------------------------
-- 15 通知
-- ---------------------------------------------------------------
CREATE TABLE t_notification (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    user_id      BIGINT UNSIGNED NOT NULL                COMMENT '接收人',
    type         VARCHAR(32)     NOT NULL                COMMENT '通知类型：REMINDER/REPORT/AUDIT/COMMENT',
    payload_json JSON            NULL                    COMMENT '内容',
    read_at      DATETIME        NULL                    COMMENT '已读时间',
    status       ENUM('PENDING','SENT','FAILED') NOT NULL DEFAULT 'PENDING' COMMENT '投递状态',
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_read (user_id, read_at),
    KEY idx_status (status),
    CONSTRAINT fk_notify_user FOREIGN KEY (user_id) REFERENCES t_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知';

-- ---------------------------------------------------------------
-- 16 消息消费幂等表
-- ---------------------------------------------------------------
CREATE TABLE t_event_consume_log (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    event_id    VARCHAR(128)    NOT NULL                COMMENT '事件 ID（业务主键+版本）',
    consumer    VARCHAR(64)     NOT NULL                COMMENT '消费者标识',
    consumed_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_event_id (event_id),
    KEY idx_consumer (consumer, consumed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息消费幂等表';

-- ---------------------------------------------------------------
-- 17 本地消息表（发件箱，保证消息不丢）
-- ---------------------------------------------------------------
CREATE TABLE t_outbox (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    event_type   VARCHAR(64)     NOT NULL                COMMENT '事件类型',
    payload_json JSON            NOT NULL                COMMENT '消息体',
    status       ENUM('NEW','SENT','FAILED') NOT NULL DEFAULT 'NEW' COMMENT '发送状态',
    retry_count  TINYINT UNSIGNED NOT NULL DEFAULT 0     COMMENT '重试次数',
    next_retry_at DATETIME       NULL                    COMMENT '下次重试时间',
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_status_retry (status, next_retry_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='本地消息表（发件箱）';

-- ---------------------------------------------------------------
-- 18 徽章定义
-- ---------------------------------------------------------------
CREATE TABLE t_badge (
    id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    code           VARCHAR(32)     NOT NULL                COMMENT '编码',
    name           VARCHAR(64)     NOT NULL                COMMENT '徽章名',
    condition_desc VARCHAR(255)    NULL                    COMMENT '获得条件描述',
    icon_url       VARCHAR(255)    NULL                    COMMENT '图标',
    PRIMARY KEY (id),
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='徽章定义';

-- ---------------------------------------------------------------
-- 19 用户徽章
-- ---------------------------------------------------------------
CREATE TABLE t_member_badge (
    id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    member_id BIGINT UNSIGNED NOT NULL                COMMENT '用户',
    badge_id  BIGINT UNSIGNED NOT NULL                COMMENT '徽章',
    earned_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '获得时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_badge (member_id, badge_id),
    CONSTRAINT fk_mb_member FOREIGN KEY (member_id) REFERENCES t_user (id),
    CONSTRAINT fk_mb_badge  FOREIGN KEY (badge_id)  REFERENCES t_badge (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户徽章';

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 结束：共 19 张表（12 张核心 + 7 张支撑）
-- =====================================================================