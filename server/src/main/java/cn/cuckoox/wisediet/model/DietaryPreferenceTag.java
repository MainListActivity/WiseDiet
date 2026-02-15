package cn.cuckoox.wisediet.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("dietary_preference_tags")
public class DietaryPreferenceTag {
    @Id
    private Long id;
    private String label;
    private String emoji;
}
