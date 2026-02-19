# 菜品库与图片策略设计文档

**日期：** 2026-02-19
**状态：** 已批准
**背景：** 今日推荐页面需要展示菜品图片，需决定图片来源和菜单数据架构。

---

## 1. 问题与约束

- 团队规模：小团队/独立开发，不具备持续维护大量内容的能力
- 图片质量预期：辅助元素，帮助用户认菜即可，不需要美食 App 水准
- 菜品范围：完全受控，从精选库中推荐，保证数据质量

---

## 2. 核心决策

### 2.1 菜单库规模：80 道精选家常菜

不追求大而全，聚焦高频、营养覆盖均衡的家常菜。

| 分类 | 数量 |
|------|------|
| 蔬菜类 | 20 道 |
| 肉禽类 | 25 道 |
| 豆制品/蛋类 | 10 道 |
| 汤类 | 10 道 |
| 主食/杂粮 | 15 道 |
| **合计** | **80 道** |

### 2.2 图片策略：食物类别占位图

**不为每道菜单独配图**，而是按食物大类准备 12 张图片，每道菜根据其所属类别自动匹配。

| 图片 key | 覆盖菜品 |
|----------|----------|
| `veggie_leafy` | 炒菠菜、炒油麦菜等绿叶菜 |
| `veggie_root` | 地三鲜、土豆丝等根茎菜 |
| `veggie_mixed` | 番茄炒蛋、西蓝花炒虾仁等混合蔬菜 |
| `meat_red` | 红烧肉、回锅肉等红肉 |
| `meat_poultry` | 宫保鸡丁、白切鸡等禽肉 |
| `seafood` | 清蒸鱼、虾仁等鱼虾 |
| `tofu_egg` | 麻婆豆腐、皮蛋等豆制品蛋类 |
| `soup_clear` | 冬瓜排骨汤等清汤 |
| `soup_thick` | 番茄蛋花汤等浓汤 |
| `staple_rice` | 杂粮饭、白米饭 |
| `staple_other` | 玉米、红薯、馒头等 |
| `default` | 兜底图，用于未分类菜品 |

**图片来源：** Unsplash 免费授权食物图，一次性下载，本地打包进 App assets。

---

## 3. LLM 集成方式调整

### 原方案（自由生成）
LLM 直接生成菜品名称 + 完整食谱 JSON → 图片和数据无法预置，质量不稳定

### 新方案（库内选菜）
1. 将 80 道菜的 ID + 名称列表作为 Prompt 上下文传给 LLM
2. LLM 从列表中选出适合今日的菜品 ID
3. 服务端根据 ID 从数据库读取食材、步骤、营养标签等完整数据
4. LLM 只需额外生成**推荐理由**（个性化的核心体现）

**优势：**
- LLM 输出从复杂 JSON 简化为"选 ID + 写理由"，幻觉风险大幅降低
- 食材克数、营养成分、烹饪步骤由人工校验的数据库保证，不依赖 LLM 生成
- 图片 key 存储在数据库中，随菜品数据一起返回，前端直接映射

---

## 4. 数据结构

### 4.1 菜品库表（dishes）

```sql
CREATE TABLE dishes (
    id          VARCHAR(20) PRIMARY KEY,  -- 如 "dish_001"
    name        VARCHAR(50) NOT NULL,
    category    VARCHAR(20) NOT NULL,     -- 对应图片 key
    difficulty  VARCHAR(10),             -- easy / medium / hard
    prep_min    INT,
    cook_min    INT,
    servings    INT DEFAULT 2,
    ingredients JSONB NOT NULL,          -- [{item, amount, unit}]
    steps       JSONB NOT NULL,          -- ["步骤1...", "步骤2..."]
    nutrient_tags JSONB,                 -- ["高蛋白", "低GI"]
    nutrients   JSONB                    -- {protein_g, carb_g, fat_g, calories}
);
```

### 4.2 前端图片映射

```dart
const Map<String, String> categoryImageMap = {
  'veggie_leafy':   'assets/images/dishes/veggie_leafy.jpg',
  'veggie_root':    'assets/images/dishes/veggie_root.jpg',
  'veggie_mixed':   'assets/images/dishes/veggie_mixed.jpg',
  'meat_red':       'assets/images/dishes/meat_red.jpg',
  'meat_poultry':   'assets/images/dishes/meat_poultry.jpg',
  'seafood':        'assets/images/dishes/seafood.jpg',
  'tofu_egg':       'assets/images/dishes/tofu_egg.jpg',
  'soup_clear':     'assets/images/dishes/soup_clear.jpg',
  'soup_thick':     'assets/images/dishes/soup_thick.jpg',
  'staple_rice':    'assets/images/dishes/staple_rice.jpg',
  'staple_other':   'assets/images/dishes/staple_other.jpg',
  'default':        'assets/images/dishes/default.jpg',
};

String getDishImage(String category) {
  return categoryImageMap[category] ?? categoryImageMap['default']!;
}
```

---

## 5. 渐进增强路径

| 阶段 | 图片方案 | 触发条件 |
|------|----------|----------|
| MVP | 类别占位图（本文方案） | 当前 |
| 成长期 | 为 Top 20 高频菜补充真实食物摄影图 | 用户留存稳定后 |
| 成熟期 | 引入 AI 生成图用于长尾菜品 | 有付费用户后，成本可承担 |

---

## 6. 管理员接口设计

### 6.1 权限模型

用户角色只有两种，存储在 `users` 表的 `role` 字段：

| 角色 | 值 | 能力 |
|------|----|------|
| 普通用户 | `USER` | 使用 App 所有功能 |
| 管理员 | `ADMIN` | 额外访问 `/admin/**` 接口和管理后台 |

**登录方式：复用现有 Google OAuth 登录流程**，无需单独开发管理员登录。

登录判断逻辑：
1. Google OAuth 回调成功，获取用户邮箱
2. 后端查询已有的 admin 白名单表，检查邮箱是否存在
3. 存在 → 签发带 `role=ADMIN` 的 JWT
4. 不存在 → 走普通用户流程，签发 `role=USER` 的 JWT

**管理后台技术栈：** HTMX + Tailwind CSS，服务端渲染，Spring Boot 直接返回 HTML 片段。选择理由：无需独立前端项目，复用后端代码，自己用够简单够用。

后端用 Spring Security 对 `/admin/**` 路径做角色校验，非 ADMIN 角色返回 403。

### 6.2 菜品管理 API

所有接口路径前缀：`/admin/dishes`，需携带有效 JWT 且 role = ADMIN。

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/admin/dishes` | 获取全部菜品列表（支持分页、按分类过滤） |
| `GET` | `/admin/dishes/{id}` | 获取单道菜详情 |
| `POST` | `/admin/dishes` | 新增菜品 |
| `PUT` | `/admin/dishes/{id}` | 更新菜品（全量替换） |
| `PATCH` | `/admin/dishes/{id}/status` | 启用 / 禁用菜品（软删除，不影响历史记录） |
| `DELETE` | `/admin/dishes/{id}` | 硬删除（谨慎使用） |

### 6.3 dishes 表补充字段

在原有结构上增加两个字段：

```sql
ALTER TABLE dishes ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE dishes ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT NOW();
```

- `is_active`：软删除标志。LLM 选菜时只查询 `is_active = true` 的菜品
- `created_at`：便于排序和审计

### 6.4 普通用户接口（只读）

普通用户只能访问 `/dishes/{id}` 获取菜品详情，不能访问任何 `/admin/**` 路径。

推荐引擎调用路径：`/recommendations/today` → 后端查询 `is_active=true` 的菜品列表 → 传给 LLM → LLM 返回选中的 ID → 后端组装完整响应。

---

## 7. 不做的事（明确排除）

- **不**为每道菜单独配图（维护成本过高）
- **不**在 MVP 阶段接入 AI 图片生成（成本高、体验不稳定）
- **不**爬取第三方菜谱图片（版权风险）
- **不**允许 LLM 自由生成菜品名称（数据质量无法保证）
