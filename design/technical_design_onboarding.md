# User Onboarding & First Page Technical Design

## 1. Overview
This document outlines the technical design for the User Onboarding flow (First Page) of the Wise Diet application.
The flow covers:
1.  **OAuth2 Login** (Entry point).
2.  **User Profile Collection** (Wizard: Basic Info -> Tags -> Family Size).
3.  **AI Strategy Generation** (Loading -> Report).

## 2. Database Design (PostgreSQL)

We will use PostgreSQL with R2DBC for reactive access.

### 2.1 Schema

```sql
-- Users Table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    oauth_provider VARCHAR(50) NOT NULL, -- e.g., 'google', 'github'
    oauth_id VARCHAR(100) NOT NULL,      -- Unique ID from provider
    email VARCHAR(255),
    nickname VARCHAR(100),
    avatar_url TEXT,

    -- Physical Attributes
    gender VARCHAR(20),       -- 'MALE', 'FEMALE', 'OTHER'
    birth_year INT,           -- Storing year is better than age for longevity
    height_cm FLOAT,
    weight_kg FLOAT,

    -- Family/Dining Config
    dining_headcount INT DEFAULT 1,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_oauth_user UNIQUE (oauth_provider, oauth_id)
);

-- Tags Configuration Table (Admin managed, Dynamic Fetch)
CREATE TABLE tags (
    id BIGSERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL, -- 'OCCUPATION', 'HEALTH_GOAL', 'DIETARY_PREF', 'STATUS'
    name VARCHAR(100) NOT NULL,
    icon_url TEXT,
    description TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User-Tag Association (Many-to-Many)
CREATE TABLE user_tags (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, tag_id)
);

-- AI Strategy Reports (Result of Onboarding)
CREATE TABLE strategy_reports (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- The core content (JSON or Text)
    summary_text TEXT,  -- "Your Low GI strategy..."
    full_report_json JSONB, -- Structured data for the report UI

    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 3. Redis Cache Design

Redis acts as an L2 Cache for R2DBC and stores ephemeral session data if needed.

| Key Pattern | Type | TTL | Description |
| :--- | :--- | :--- | :--- |
| `app:config:tags` | List/JSON | 24 Hours | Caches the full list of available tags to reduce DB load on high-concurrency onboarding. |
| `user:profile:{userId}` | Hash/JSON | 1 Hour | Caches frequently accessed user profile data (height, weight, tags) to speed up "Today" page rendering. |

**Cache Strategy:**
*   **Tags:** Read-through. If missing in Redis, fetch from DB, write to Redis. Invalidate on Admin update.
*   **User Profile:** Write-through or Cache-Aside. Update Redis when User updates profile.

## 4. Backend Design (Java / Spring WebFlux)

### 4.1 Package Structure (`cn.cuckoox.wisediet`)
*   `config`: Security (OAuth2), R2DBC, Redis, AI Config.
*   `controller`: `OnboardingController`, `TagController`.
*   `service`: `UserService`, `TagService`, `AiStrategyService`.
*   `repository`: `UserRepository`, `TagRepository`, `UserTagRepository` (ReactiveCrudRepository).
*   `model`: Entities (`User`, `Tag`) and DTOs.

### 4.2 API Endpoints

#### A. Tag Configuration
*   `GET /api/v1/tags`
    *   **Response:** List of Tags grouped by category.
    *   **Logic:** Check Redis `app:config:tags`. If miss, query DB, cache, return.

#### B. User Onboarding
*   `POST /api/v1/onboarding/submit`
    *   **Request Body:**
        ```json
        {
          "gender": "MALE",
          "heightCm": 175,
          "weightKg": 70,
          "birthYear": 1990,
          "tagIds": [1, 5, 12],
          "diningHeadcount": 2
        }
        ```
    *   **Logic:**
        1.  Validate input.
        2.  Get current authenticated User (from Security Context).
        3.  Update `users` table.
        4.  Update `user_tags` table (transactional).
        5.  **AI Generation:** Call `AiStrategyService` to generate the "Strategy Report" based on profile + tags.
        6.  Save Report to `strategy_reports`.
        7.  Return Report + User Profile.

### 4.3 AI Integration (Spring AI)
*   **Prompt Template:**
    ```text
    User Profile: {age} years old, {gender}, {height}cm, {weight}kg.
    Occupation/Status Tags: {tags}.
    Family Size: {headcount}.

    Task: Generate a dietary strategy summary and 3 key health tips.
    Format: JSON.
    ```
*   **Service:** `AiStrategyService` calls OpenAI/DeepSeek via Spring AI `ChatClient`.

## 5. Frontend Design (Flutter + Riverpod)

### 5.1 Architecture
*   **State Management:** Riverpod (for Dependency Injection and State).
*   **Navigation:** GoRouter (standard for deep linking and flow).
*   **Architecture Pattern:** MVVM (Model - View - ViewModel/Provider).

### 5.2 Dependencies (to be added)
*   `flutter_riverpod`
*   `riverpod_annotation`
*   `json_annotation`
*   `go_router`
*   `dio` (HTTP Client)
*   `shared_preferences` (Local Cache)

### 5.3 Riverpod Providers

*   **`authProvider`**: Manages OAuth status.
    *   State: `Authenticated(User) | Unauthenticated | Loading`
    *   Methods: `login()`, `logout()`.
*   **`tagProvider`**: FutureProvider. Fetches tags from `/api/v1/tags`.
    *   Caches in memory for the session.
*   **`onboardingStateProvider`**: NotifierProvider.
    *   State:
        ```dart
        class OnboardingState {
           final double? height;
           final double? weight;
           final String? gender;
           final Set<int> selectedTagIds;
           final int diningHeadcount;
           final bool isSubmitting;
           // ...
        }
        ```
    *   Methods: `updateHeight`, `toggleTag`, `submit()`.

### 5.4 Widget/Page Flow

1.  **`LoginPage`**:
    *   Center Widget: "Login with Google/GitHub".
    *   Action: Triggers OAuth web flow. On success, backend returns JWT/Session, app navigates to `CheckState`.
2.  **`CheckState`**:
    *   Logic: Fetch User Profile.
    *   If `user.hasCompletedOnboarding`: Go to `HomePage`.
    *   Else: Go to `OnboardingWizardPage`.
3.  **`OnboardingWizardPage`**:
    *   **Layout:** `PageView` with `NeverScrollableScrollPhysics` (controlled by Next buttons).
    *   **Step 1: BasicInfo**: Form Fields (Height, Weight, Gender).
    *   **Step 2: TagCloud**:
        *   Fetch tags via `ref.watch(tagProvider)`.
        *   Display `Wrap` of `FilterChip`s.
        *   Selection updates `onboardingStateProvider`.
    *   **Step 3: Family**: Slider for Headcount.
    *   **Step 4: Loading**:
        *   Display Lottie animation.
        *   Trigger `ref.read(onboardingViewModel).submit()`.
    *   **Step 5: Result (Strategy Report)**:
        *   Display the returned AI report.
        *   Button: "Start My Plan" -> Navigates to `HomePage`.

### 5.5 Client-Side Caching
*   **User Profile:** Upon successful login/onboarding, store critical user attributes (ID, Name, Avatar) in `SharedPreferences` for immediate app launch display while fetching fresh data in background.
*   **Tags:** Tags are fetched from API. We can use `dio_cache_interceptor` or standard Riverpod caching (`keepAlive`) to avoid re-fetching during the same session.

## 6. Security (OAuth2)
*   **Flow:** Authorization Code Flow.
*   **Backend:** Acts as OAuth2 Client.
*   **Frontend:** Opens system browser/webview to backend `/oauth2/authorization/{provider}`.
*   **Success:** Backend redirects to Custom Scheme (e.g., `wisediet://login-success?token=xyz`) or sets a secure HttpOnly cookie. Given mobile app, Token-based (JWT) via URL redirect or Deep Link is common.
