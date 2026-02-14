package cn.cuckoox.wisediet.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("meal_plans")
public class MealPlan {
    @Id
    private Long id;
    private Long userId;
    private LocalDate date;
    private String status;
}
