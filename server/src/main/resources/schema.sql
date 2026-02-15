-- 职业标签表：存储职业相关的标签信息
CREATE TABLE IF NOT EXISTS "occupation_tags" (
    id SERIAL PRIMARY KEY,
    label VARCHAR(255) NOT NULL, -- 标签名称
    icon VARCHAR(255),           -- 图标标识
    category VARCHAR(255)        -- 标签分类
);

-- 用户档案表：存储用户的身体数据和基本画像
CREATE TABLE IF NOT EXISTS "user_profiles" (
    id SERIAL PRIMARY KEY,
    gender VARCHAR(50),          -- 性别
    age INT,                     -- 年龄
    height FLOAT,                -- 身高 (cm)
    weight FLOAT,                -- 体重 (kg)
    occupation_tag_ids TEXT,     -- 关联的职业标签ID (逗号分隔或JSON)
    family_members INT           -- 家庭成员数量
);

-- 用户表：核心用户账号信息
CREATE TABLE IF NOT EXISTS "users" (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL, -- 用户邮箱
    provider VARCHAR(50),        -- 登录提供方 (如 google)
    provider_user_id VARCHAR(255), -- 第三方平台的用户ID
    onboarding_step INT          -- 记录用户Onboarding完成到的步骤
);

-- 管理员白名单表：控制特定用户的权限
CREATE TABLE IF NOT EXISTS "admin_whitelist" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL      -- 关联的用户ID
);

-- 膳食计划表：记录用户每一天的生成的菜单计划
CREATE TABLE IF NOT EXISTS "meal_plans" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,     -- 关联用户ID
    date DATE NOT NULL,          -- 计划对应的日期
    status VARCHAR(20) NOT NULL DEFAULT 'pending' -- 状态 (pending: 生成中/待确认, completed: 已生成)
);

-- 菜品表：膳食计划中包含的具体菜品
CREATE TABLE IF NOT EXISTS "dishes" (
    id SERIAL PRIMARY KEY,
    meal_plan_id BIGINT NOT NULL, -- 关联的膳食计划ID
    name VARCHAR(255) NOT NULL,   -- 菜品名称
    recommendation_reason TEXT,   -- 推荐理由
    image_url TEXT,               -- 菜品图片URL
    difficulty INT DEFAULT 3,     -- 烹饪难度 (例如 1-5)
    prep_min INT DEFAULT 10,      -- 准备时间 (分钟)
    cook_min INT DEFAULT 10,      -- 烹饪时间 (分钟)
    nutrient_tags TEXT,           -- 营养标签 (如 高蛋白, 低碳水)
    selected BOOLEAN DEFAULT FALSE, -- 用户是否选中该菜品
    meal_type VARCHAR(20) NOT NULL  -- 餐别 (BREAKFAST, LUNCH, DINNER)
);

COMMENT ON TABLE "occupation_tags" IS '职业标签表：存储职业相关的标签信息';
COMMENT ON COLUMN "occupation_tags".label IS '标签名称';
COMMENT ON COLUMN "occupation_tags".icon IS '图标标识';
COMMENT ON COLUMN "occupation_tags".category IS '标签分类';

COMMENT ON TABLE "user_profiles" IS '用户档案表：存储用户的身体数据和基本画像';
COMMENT ON COLUMN "user_profiles".gender IS '性别';
COMMENT ON COLUMN "user_profiles".age IS '年龄';
COMMENT ON COLUMN "user_profiles".height IS '身高 (cm)';
COMMENT ON COLUMN "user_profiles".weight IS '体重 (kg)';
COMMENT ON COLUMN "user_profiles".occupation_tag_ids IS '关联的职业标签ID (逗号分隔或JSON)';
COMMENT ON COLUMN "user_profiles".family_members IS '家庭成员数量';

COMMENT ON TABLE "users" IS '用户表：核心用户账号信息';
COMMENT ON COLUMN "users".email IS '用户邮箱';
COMMENT ON COLUMN "users".provider IS '登录提供方 (如 google)';
COMMENT ON COLUMN "users".provider_user_id IS '第三方平台的用户ID';
COMMENT ON COLUMN "users".onboarding_step IS '记录用户Onboarding完成到的步骤';

COMMENT ON TABLE "admin_whitelist" IS '管理员白名单表：控制特定用户的权限';
COMMENT ON COLUMN "admin_whitelist".user_id IS '关联的用户ID';

COMMENT ON TABLE "meal_plans" IS '膳食计划表：记录用户每一天的生成的菜单计划';
COMMENT ON COLUMN "meal_plans".user_id IS '关联用户ID';
COMMENT ON COLUMN "meal_plans".date IS '计划对应的日期';
COMMENT ON COLUMN "meal_plans".status IS '状态 (pending: 生成中/待确认, completed: 已生成)';

COMMENT ON TABLE "dishes" IS '菜品表：膳食计划中包含的具体菜品';
COMMENT ON COLUMN "dishes".meal_plan_id IS '关联的膳食计划ID';
COMMENT ON COLUMN "dishes".name IS '菜品名称';
COMMENT ON COLUMN "dishes".recommendation_reason IS '推荐理由';
COMMENT ON COLUMN "dishes".image_url IS '菜品图片URL';
COMMENT ON COLUMN "dishes".difficulty IS '烹饪难度 (例如 1-5)';
COMMENT ON COLUMN "dishes".prep_min IS '准备时间 (分钟)';
COMMENT ON COLUMN "dishes".cook_min IS '烹饪时间 (分钟)';
COMMENT ON COLUMN "dishes".nutrient_tags IS '营养标签 (如 高蛋白, 低碳水)';
COMMENT ON COLUMN "dishes".selected IS '用户是否选中该菜品';
COMMENT ON COLUMN "dishes".meal_type IS '餐别 (BREAKFAST, LUNCH, DINNER)';

