package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.DietaryPreferenceTag;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DietaryPreferenceTagRepository extends R2dbcRepository<DietaryPreferenceTag, Long> {
}
