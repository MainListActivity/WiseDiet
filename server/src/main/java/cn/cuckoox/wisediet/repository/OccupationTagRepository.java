package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.OccupationTag;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OccupationTagRepository extends R2dbcRepository<OccupationTag, Long> {
}
