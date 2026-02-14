# Today's Meal Recommendations Backend API Design

**Date:** 2026-02-14
**Status:** Approved

## Overview

Create the backend API for the "Today" meal recommendation feature. This is the first post-onboarding feature — the core daily workflow entry point. Uses mock data (no LLM integration yet).

## Data Model

### `meal_plans` table

| Column   | Type         | Description                      |
|----------|--------------|----------------------------------|
| id       | SERIAL PK    |                                  |
| user_id  | BIGINT       | FK to users                      |
| date     | DATE         | Plan date                        |
| status   | VARCHAR(20)  | `pending` or `confirmed`         |

### `dishes` table

| Column                | Type         | Description                    |
|-----------------------|--------------|--------------------------------|
| id                    | SERIAL PK    |                                |
| meal_plan_id          | BIGINT       | FK to meal_plans               |
| name                  | VARCHAR(255) | Dish name                      |
| recommendation_reason | TEXT         | AI-generated reason            |
| image_url             | TEXT         | AI image URL                   |
| difficulty            | INT          | 1-5 stars                      |
| prep_min              | INT          | Prep time in minutes           |
| cook_min              | INT          | Cooking time in minutes        |
| nutrient_tags         | TEXT         | Comma-separated tags           |
| selected              | BOOLEAN      | User's selection               |
| meal_type             | VARCHAR(20)  | breakfast/lunch/dinner/snack   |

## API Endpoints

### `GET /api/today/recommendations`

Returns today's meal plan for the authenticated user. If no plan exists for today, creates one with mock data.

**Response (200):**
```json
{
  "id": 1,
  "date": "2026-02-14",
  "status": "pending",
  "dishes": [
    {
      "id": 1,
      "name": "Grilled Salmon & Asparagus",
      "recommendationReason": "Rich in B vitamins for tonight's overtime",
      "imageUrl": "...",
      "difficulty": 3,
      "prepMin": 10,
      "cookMin": 10,
      "nutrientTags": "High Protein,Low GI",
      "selected": false,
      "mealType": "dinner"
    }
  ]
}
```

**Errors:** 401 Unauthorized (no JWT), 403 Forbidden (onboarding incomplete)

### `POST /api/today/confirm`

Confirms selected dishes for today's meal plan.

**Request body:**
```json
{
  "dishIds": [1, 3]
}
```

**Response (200):** Updated meal plan with status `confirmed` and selected flags set.

**Errors:** 401, 403, 404 (no plan for today)

## Security

- Both endpoints require JWT authentication (handled by `JwtAuthenticationFilter`)
- Both endpoints require completed onboarding (handled by `OnboardingGateFilter`)
- User scoping via `CurrentUserService`

## Implementation Layers

1. Entity classes: `MealPlan`, `Dish`
2. Repositories: `MealPlanRepository`, `DishRepository`
3. Service: `TodayService` (mock data generation, confirm logic)
4. Controller: `TodayController`
5. DTO: `ConfirmMenuRequest`, `MealPlanResponse`
