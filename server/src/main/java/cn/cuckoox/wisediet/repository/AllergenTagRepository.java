package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.AllergenTag;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AllergenTagRepository extends R2dbcRepository<AllergenTag, Long> {
}
