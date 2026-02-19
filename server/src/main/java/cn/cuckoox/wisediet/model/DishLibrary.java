package cn.cuckoox.wisediet.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("dish_library")
public class DishLibrary {
    @Id
    private Long id;
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
    private Boolean isActive;
    private LocalDateTime createdAt;
}
