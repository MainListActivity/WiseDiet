# OAuth State CSRF Fix Design

## Problem

The OAuth flow has a CSRF vulnerability: the `state` parameter generated in `getAuthUri()` is returned to the client but never stored server-side. In `login()`, the `state` from the callback is used directly without validation, allowing attackers to craft malicious OAuth callbacks with arbitrary state values.

## Solution

Store the OAuth `state` in Redis with a 5-minute TTL. Validate and consume (delete) the state on login callback.

## Changes

### 1. SessionStore — Add two methods

- `saveOAuthState(String state)` — stores `oauth:state:{state}` key with 5min TTL
- `validateAndConsumeOAuthState(String state)` — checks key exists, deletes it, returns validity

### 2. OAuthService.getAuthUri()

Change from `.map()` to `.flatMap()` to save the generated state to Redis before returning the response.

### 3. OAuthService.login()

Add state validation as the first step: call `validateAndConsumeOAuthState(state)` before proceeding with the token exchange. Reject with `InvalidOAuthStateException` if state is invalid or expired.

### 4. New Exception

`InvalidOAuthStateException` — thrown when state is invalid/expired/missing.

### What Doesn't Change

- `AuthController` API signatures unchanged
- `AuthUriResponse` / `OAuthLoginRequest` DTOs unchanged
- Redis key namespace isolated: `oauth:state:` prefix, no conflict with existing `session:` prefix
