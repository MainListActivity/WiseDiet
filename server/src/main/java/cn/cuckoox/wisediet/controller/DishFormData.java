package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.DishLibraryRequest;
import lombok.Data;

@Data
public class DishFormData {
    private String name;
    private String category;
    private Integer difficulty;
    private Integer prepMin;
    private Integer cookMin;
    private Integer servings;
    private String ingredients;
    private String steps;
    private String nutrientTags;
    private String nutrients;

    public DishLibraryRequest toRequest() {
        return new DishLibraryRequest(name, category, difficulty, prepMin, cookMin, servings,
                ingredients, steps, nutrientTags, nutrients);
    }
}
