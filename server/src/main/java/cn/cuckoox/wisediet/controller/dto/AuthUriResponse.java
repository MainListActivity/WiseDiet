package cn.cuckoox.wisediet.controller.dto;

import java.util.Set;

public record AuthUriResponse(String authUri, String state, String clientId, String redirectUri, Set<String> scopes) {
}
