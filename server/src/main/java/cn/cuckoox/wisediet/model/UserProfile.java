package cn.cuckoox.wisediet.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("user_profiles")
public class UserProfile {
    @Id
    private Long id;
    private String gender;
    private Integer age;
    private Double height;
    private Double weight;
    private String occupationTagIds; // Stored as comma-separated string
    private Integer familyMembers;
}
