package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.UserProfile;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserProfileRepository extends R2dbcRepository<UserProfile, Long> {
}
