# Social Login (Google/GitHub) + Stateful JWT + Onboarding Gate Design

Date: 2026-01-30

## Goals
- Native-first social login on mobile: Google Sign-In SDK; GitHub via system browser OAuth.
- Backend controls JWT lifecycle with Redis-backed stateful validation.
- Global onboarding gate: only `/auth/**` and `/onboarding/**` allowed when `onboardingStep > 0`.
- Admin can revoke all sessions for a user by userId; admin access via DB whitelist (no roles).

## Non-Goals
- Web login UI
- Role-based access control
- Payment/checkout or external ordering

## Architecture Overview
- **Mobile**: Flutter app initiates OAuth. Google uses native SDK. GitHub uses system browser.
- **Backend (WebFlux)**: handles OAuth callbacks, issues JWTs, stores session entries in Redis.
- **Redis**: session store keyed by `jti` + per-user index for global revocation.
- **DB**: users table (with `onboardingStep`) and admin whitelist table (userId keyed).

## Auth Flow
1) User taps “Continue with Google/GitHub”.
2) OAuth completes, backend resolves profile and creates/updates user.
3) Backend issues access + refresh JWTs with `sub=userId`, `jti`, `exp`, `iat`.
4) Backend writes Redis keys:
   - `session:{jti}` => `{userId, type, exp}` with TTL matching token
   - `user:{userId}:sessions` => set of `jti` for global revoke
5) Client stores tokens securely; attaches access token on each request.

## Token Policy
- Access token: 15 minutes
- Refresh token: 30 days
- Validation on every request: JWT signature + Redis `session:{jti}` presence

## Onboarding Gate
- If `onboardingStep > 0`, only allow:
  - `/auth/**`
  - `/onboarding/**`
- All other endpoints return 403 with reason `ONBOARDING_REQUIRED`.

## Admin Revoke API
- Endpoint: `POST /admin/sessions/revoke`
- Request: `{ "userId": "..." }`
- Auth: caller must be in `admin_whitelist` table (by userId).
- Behavior: delete all `session:{jti}` for target user; remove index set.

## Data Model (Minimum)
- `users`: `id`, `email`, `provider`, `providerUserId`, `onboardingStep`, `createdAt`, `updatedAt`
- `admin_whitelist`: `userId`, `createdAt`

## Frontend Behavior
- If not logged in: route to login.
- If logged in and `onboardingStep > 0`: route to onboarding.
- If session revoked: show "账号暂不可用，稍后重试" and clear tokens.

## Error Handling
- OAuth failure: generic retry message.
- Invalid/revoked session: 401 and client logout.

## Testing (TDD)
- Integration tests first using WebTestClient + reactive repositories.
- Use `StepVerifier.create().expectNext().verifyComplete()`; no `.block()` in tests.

### Acceptance Criteria (Given-When-Then)
- Given `onboardingStep=1`, when calling non-whitelisted API, then 403 with `ONBOARDING_REQUIRED`.
- Given valid JWT and Redis session, when calling any API, then 200.
- Given admin in whitelist, when revoking user, then all sessions are removed and subsequent requests return 401.
- Given revoked session, when app receives 401, then it clears tokens and shows "账号暂不可用，稍后重试".

## Open Questions
- Confirm if GitHub OAuth uses PKCE and whether backend or app handles code exchange (default: backend).
- Confirm if refresh rotation is required (default: no rotation).
