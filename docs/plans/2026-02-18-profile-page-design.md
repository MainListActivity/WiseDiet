# Profile 页面设计文档

**日期：** 2026-02-18
**状态：** 已批准

---

## 1. 目标

为 WiseDiet 的 Profile 页面（现为空壳）实现完整的"查看 + 内联编辑个人信息"功能，展示用户在 Onboarding 阶段填写的所有数据，并允许用户随时修改。

---

## 2. 页面布局

`Scaffold` + `AppBar`（标题：个人信息）+ `ListView`（支持亮/暗模式跟随系统）。

页面分为四个 `Card` 区块，最底部是退出登录按钮。

```
┌─────────────────────────────────┐
│  ← 个人信息                      │
├─────────────────────────────────┤
│  ┌─── 基本信息 ─────────────┐   │
│  │ 性别        男      [✏️] │   │
│  │ 年龄        28 岁   [✏️] │   │
│  │ 身高        175 cm  [✏️] │   │
│  │ 体重        70 kg   [✏️] │   │
│  └──────────────────────────┘   │
│  ┌─── 居家参数 ─────────────┐   │
│  │ 家庭用餐人数  3 人   [✏️] │   │
│  └──────────────────────────┘   │
│  ┌─── 职业标签 ─────────────┐   │
│  │ [程序员] [高压] [+编辑]   │   │
│  └──────────────────────────┘   │
│  ┌─── 饮食偏好与过敏 ───────┐   │
│  │ 过敏原: [花生] [牛奶]     │   │
│  │ 饮食限制: [低GI]  [+编辑] │   │
│  │ 自定义忌口: 香菜    [✏️] │   │
│  └──────────────────────────┘   │
│  ─────────────────────────────  │
│  [退出登录]                      │
└─────────────────────────────────┘
```

---

## 3. 内联编辑交互细节

### 数值类字段（年龄 / 身高 / 体重 / 家庭人数）
- 点击铅笔图标 → 行内变为 `TextField`（数字键盘）+ "✓" 确认按钮
- 失焦或点击确认 → 调用 `PATCH /api/profile` 局部保存
- 保存成功 → 切回只读态
- 保存失败 → 显示 SnackBar 错误提示

### 性别字段
- 点击铅笔 → 行内展开三个 Radio 选项（男 / 女 / 其他）
- 选择后立即保存，切回只读

### 职业标签 / 过敏原 / 饮食偏好
- 点击"编辑"按钮 → 弹出 `BottomSheet`，复用 Onboarding 的 Tag 选择 UI
- 确认后调用 API 保存

### 自定义忌口食材
- 点击铅笔 → 弹出带 `TextField` 的 `BottomSheet`，逗号分隔多个食材

---

## 4. 设计稿

位于 `design/13_profile/`，包含：
- `code.html`：完整 HTML 设计稿，主题色 `#4b7c5a`（Cyber Sage Green），支持亮/暗模式切换
- `screen.png`：截图（手动生成）

---

## 5. 后端 API

### 新增端点（`ProfileController`）

| 方法   | 路径            | 说明                                   |
|--------|----------------|----------------------------------------|
| GET    | `/api/profile` | 获取当前登录用户的 UserProfile          |
| PATCH  | `/api/profile` | 局部更新 UserProfile（只含要改的字段）  |

- 通过 `CurrentUserService` 识别当前用户，禁止在 Controller 中直接解析 token
- 未登录返回 401
- 数据流：`ProfileController` → `ProfileService` → `UserProfileRepository`

### PATCH 请求体（所有字段可选）
```json
{
  "gender": "male",
  "age": 28,
  "height": 175.0,
  "weight": 70.0,
  "familyMembers": 3,
  "occupationTagIds": "1,2,3",
  "allergenTagIds": "4,5",
  "dietaryPreferenceTagIds": "6",
  "customAvoidedIngredients": "香菜,榴莲"
}
```

---

## 6. 前端实现关键点

- **状态管理**：使用 Riverpod，新建 `profileProvider` 持有 `AsyncValue<UserProfile>`
- **State**：`ProfileState`（loading / data / editing field / saving / error）
- **复用**：Tag 选择器复用 Onboarding 的 `AllergyTagSelector`、`OccupationTagSelector`
- **i18n**：新增 Profile 页面所需的中英文 key

---

## 7. 编码顺序（TDD）

1. 设计稿 HTML（`design/13_profile/code.html`）
2. 服务端集成测试（`GET /api/profile` 未登录 401 + 登录 200，`PATCH /api/profile` 各字段更新）
3. 服务端实现（`ProfileController` + `ProfileService`）
4. 客户端 Widget 测试（展示四个模块、内联编辑交互）
5. 客户端实现（`ProfileScreen` + `profileProvider`）
