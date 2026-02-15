package cn.cuckoox.wisediet.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("user_profiles")
public class UserProfile {
    @Id
    private Long id;
    @NotBlank
    @Pattern(regexp = "(?i)male|female|other")
    private String gender;
    @NotNull
    @Min(16)
    @Max(80)
    private Integer age;
    @NotNull
    @DecimalMin("140")
    @DecimalMax("220")
    private Double height;
    @NotNull
    @DecimalMin("35")
    @DecimalMax("150")
    private Double weight;
    private String occupationTagIds; // Stored as comma-separated string
    @NotNull
    @Min(1)
    @Max(12)
    private Integer familyMembers;
}
