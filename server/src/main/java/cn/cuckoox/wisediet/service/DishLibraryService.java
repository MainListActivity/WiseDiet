package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.DishLibraryRequest;
import cn.cuckoox.wisediet.controller.dto.DishLibraryResponse;
import cn.cuckoox.wisediet.model.DishLibrary;
import cn.cuckoox.wisediet.repository.DishLibraryRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class DishLibraryService {

    private final DishLibraryRepository dishLibraryRepository;

    public DishLibraryService(DishLibraryRepository dishLibraryRepository) {
        this.dishLibraryRepository = dishLibraryRepository;
    }

    public Flux<DishLibraryResponse> findAll(int page, int size, boolean activeOnly) {
        PageRequest pageable = PageRequest.of(page, size);
        Flux<DishLibrary> flux = activeOnly
                ? dishLibraryRepository.findAllActive(pageable)
                : dishLibraryRepository.findAllPaged(pageable);
        return flux.map(this::toResponse);
    }

    public Mono<Long> count(boolean activeOnly) {
        return activeOnly ? dishLibraryRepository.countActive() : dishLibraryRepository.countAll();
    }

    public Mono<DishLibraryResponse> findById(Long id) {
        return dishLibraryRepository.findById(id).map(this::toResponse);
    }

    public Mono<DishLibraryResponse> create(DishLibraryRequest request) {
        DishLibrary entity = new DishLibrary();
        entity.setName(request.name());
        entity.setCategory(request.category());
        entity.setDifficulty(request.difficulty() != null ? request.difficulty() : 2);
        entity.setPrepMin(request.prepMin() != null ? request.prepMin() : 5);
        entity.setCookMin(request.cookMin() != null ? request.cookMin() : 15);
        entity.setServings(request.servings() != null ? request.servings() : 2);
        entity.setIngredients(request.ingredients() != null ? request.ingredients() : "[]");
        entity.setSteps(request.steps() != null ? request.steps() : "[]");
        entity.setNutrientTags(request.nutrientTags());
        entity.setNutrients(request.nutrients());
        entity.setIsActive(true);
        return dishLibraryRepository.save(entity).map(this::toResponse);
    }

    public Mono<DishLibraryResponse> update(Long id, DishLibraryRequest request) {
        return dishLibraryRepository.findById(id)
                .flatMap(entity -> {
                    entity.setName(request.name());
                    entity.setCategory(request.category());
                    if (request.difficulty() != null) entity.setDifficulty(request.difficulty());
                    if (request.prepMin() != null) entity.setPrepMin(request.prepMin());
                    if (request.cookMin() != null) entity.setCookMin(request.cookMin());
                    if (request.servings() != null) entity.setServings(request.servings());
                    if (request.ingredients() != null) entity.setIngredients(request.ingredients());
                    if (request.steps() != null) entity.setSteps(request.steps());
                    entity.setNutrientTags(request.nutrientTags());
                    entity.setNutrients(request.nutrients());
                    return dishLibraryRepository.save(entity);
                })
                .map(this::toResponse);
    }

    public Mono<DishLibraryResponse> updateStatus(Long id, boolean isActive) {
        return dishLibraryRepository.findById(id)
                .flatMap(entity -> {
                    entity.setIsActive(isActive);
                    return dishLibraryRepository.save(entity);
                })
                .map(this::toResponse);
    }

    public Mono<Void> delete(Long id) {
        return dishLibraryRepository.deleteById(id);
    }

    private DishLibraryResponse toResponse(DishLibrary d) {
        return new DishLibraryResponse(
                d.getId(), d.getName(), d.getCategory(),
                d.getDifficulty(), d.getPrepMin(), d.getCookMin(), d.getServings(),
                d.getIngredients(), d.getSteps(), d.getNutrientTags(), d.getNutrients(),
                d.getIsActive(), d.getCreatedAt()
        );
    }
}
