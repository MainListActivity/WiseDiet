package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.DishLibrary;
import org.springframework.data.domain.Pageable;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface DishLibraryRepository extends ReactiveCrudRepository<DishLibrary, Long> {

    @Query("SELECT * FROM dish_library WHERE is_active = true ORDER BY id LIMIT :#{#pageable.pageSize} OFFSET :#{#pageable.offset}")
    Flux<DishLibrary> findAllActive(Pageable pageable);

    @Query("SELECT COUNT(*) FROM dish_library WHERE is_active = true")
    Mono<Long> countActive();

    @Query("SELECT * FROM dish_library ORDER BY id LIMIT :#{#pageable.pageSize} OFFSET :#{#pageable.offset}")
    Flux<DishLibrary> findAllPaged(Pageable pageable);

    @Query("SELECT COUNT(*) FROM dish_library")
    Mono<Long> countAll();
}
