# Bottom Navigation Framework Design

**Date:** 2026-02-18
**Status:** Approved

## Goal

Add a bottom navigation bar to the Flutter client so users can navigate between the app's 3 core modules instead of being stuck on the Today screen.

## Architecture

Use GoRouter's `StatefulShellRoute.indexedStack` to wrap 3 branches with a shared `Scaffold` + `BottomNavigationBar`. This preserves each tab's state and integrates with the existing GoRouter navigation system.

## Route Structure

```
StatefulShellRoute.indexedStack (MainShell)
├── Branch 0: /home         → TodaySmartMenuFeedScreen (existing)
├── Branch 1: /shopping      → ShoppingPlaceholderScreen (placeholder)
└── Branch 2: /history       → HistoryPlaceholderScreen (placeholder)
                └── /history/profile → ProfileScreen (new)
```

## Bottom Navigation Tabs

| Index | Label (zh/en) | Icon | Route |
|-------|---------------|------|-------|
| 0 | 今日 / Today | `Icons.restaurant_menu` | `/home` |
| 1 | 采购 / Shopping | `Icons.shopping_cart_outlined` | `/shopping` |
| 2 | 档案 / History | `Icons.person_outline` | `/history` |

## New Files

1. **`lib/app/main_shell.dart`** — Scaffold with BottomNavigationBar, receives GoRouter `navigationShell`
2. **`lib/features/shopping/screens/shopping_placeholder_screen.dart`** — Shopping placeholder page
3. **`lib/features/history/screens/history_placeholder_screen.dart`** — History page with Profile card at top + placeholder content
4. **`lib/features/history/screens/profile_screen.dart`** — Profile detail page with logout button
5. **`lib/features/history/widgets/profile_card.dart`** — Tappable avatar + nickname card widget

## Modified Files

1. **`lib/app/router.dart`** — Wrap routes in `StatefulShellRoute.indexedStack`
2. **`lib/l10n/app_en.arb`** + **`app_zh.arb`** — Add navigation labels and profile/placeholder i18n keys
3. **Redirect logic in router** — Ensure `/shopping` and `/history` are login-protected

## History & Profile Tab Layout

```
┌─────────────────────────┐
│  👤 Avatar   Nickname    │  ← ProfileCard, tap → /history/profile
│     View profile  >      │
├─────────────────────────┤
│                          │
│   History (placeholder)  │
│   "Coming soon"          │
│                          │
└─────────────────────────┘
```

## ProfileScreen Content

- User avatar and nickname display (placeholder data for now)
- Logout button (calls existing `AuthController.logout()`)

## Testing

- Bottom nav renders 3 tabs
- Tab switching displays correct page
- Placeholder screens render correctly
- ProfileCard renders and is tappable
- ProfileScreen renders with logout button
- Logout calls AuthController.logout()
- Route redirect protection for unauthenticated users
