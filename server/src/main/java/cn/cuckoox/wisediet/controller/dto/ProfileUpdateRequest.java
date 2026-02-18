package cn.cuckoox.wisediet.controller.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfileUpdateRequest(
        String gender,
        Integer age,
        Double height,
        Double weight,
        Integer familyMembers,
        String occupationTagIds,
        String allergenTagIds,
        String dietaryPreferenceTagIds,
        String customAvoidedIngredients
) {}
