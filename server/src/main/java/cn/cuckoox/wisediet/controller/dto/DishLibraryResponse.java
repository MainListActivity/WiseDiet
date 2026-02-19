package cn.cuckoox.wisediet.controller.dto;

import java.time.LocalDateTime;

public record DishLibraryResponse(
        Long id,
        String name,
        String category,
        Integer difficulty,
        Integer prepMin,
        Integer cookMin,
        Integer servings,
        String ingredients,
        String steps,
        String nutrientTags,
        String nutrients,
        Boolean isActive,
        LocalDateTime createdAt
) {}
