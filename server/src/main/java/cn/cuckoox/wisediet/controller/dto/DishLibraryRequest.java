package cn.cuckoox.wisediet.controller.dto;

public record DishLibraryRequest(
        String name,
        String category,
        Integer difficulty,
        Integer prepMin,
        Integer cookMin,
        Integer servings,
        String ingredients,
        String steps,
        String nutrientTags,
        String nutrients
) {}
