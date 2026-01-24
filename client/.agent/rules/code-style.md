---
trigger: always_on
---


**TDD 实施策略：**

1. **Widget 测试优先**
   ```dart
   testWidgets('should display user list when data loaded', 
       (WidgetTester tester) async {
     // Given: Mock 数据源
     // When: 渲染 Widget
     // Then: 验证 UI 元素
   });
   ```

2. **业务逻辑测试（BLoC/Provider）**
   - 先写状态管理测试
   - 验证状态转换逻辑
   - Mock 所有 Repository

3. **集成测试**
   - 使用 `integration_test` 包
   - 测试完整用户流程

**编码顺序：**
1. 编写 Widget 测试（UI 行为）
2. 创建最小 Widget 实现
3. 编写状态管理测试（BLoC/Cubit）
4. 实现状态管理逻辑
5. 编写 Repository 测试
6. 实现数据层