package cn.cuckoox.wisediet.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("allergen_tags")
public class AllergenTag {
    @Id
    private Long id;
    private String label;
    private String emoji;
    private String description;
    private String category;
}
