package cn.cuckoox.wisediet.controller.dto;

import jakarta.validation.constraints.NotBlank;

public record DishLibraryRequest(
        @NotBlank String name,
        @NotBlank String category,
        Integer difficulty,
        Integer prepMin,
        Integer cookMin,
        Integer servings,
        String ingredients,
        String steps,
        String nutrientTags,
        String nutrients
) {}
