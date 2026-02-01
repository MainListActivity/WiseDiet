package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.User;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;

public interface UserRepository extends ReactiveCrudRepository<User, Long> {
}
