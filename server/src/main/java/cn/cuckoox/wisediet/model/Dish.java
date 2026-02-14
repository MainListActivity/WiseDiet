package cn.cuckoox.wisediet.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("dishes")
public class Dish {
    @Id
    private Long id;
    private Long mealPlanId;
    private String name;
    private String recommendationReason;
    private String imageUrl;
    private Integer difficulty;
    private Integer prepMin;
    private Integer cookMin;
    private String nutrientTags;
    private Boolean selected;
    private String mealType;
}
