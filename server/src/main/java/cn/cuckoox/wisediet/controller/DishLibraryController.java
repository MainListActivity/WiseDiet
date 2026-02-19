package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.DishLibraryRequest;
import cn.cuckoox.wisediet.controller.dto.DishLibraryResponse;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.security.CurrentUserService;
import cn.cuckoox.wisediet.service.DishLibraryService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/dishes")
public class DishLibraryController {

    private final DishLibraryService dishLibraryService;
    private final AdminWhitelistRepository adminWhitelistRepository;
    private final CurrentUserService currentUserService;

    public DishLibraryController(DishLibraryService dishLibraryService,
                                  AdminWhitelistRepository adminWhitelistRepository,
                                  CurrentUserService currentUserService) {
        this.dishLibraryService = dishLibraryService;
        this.adminWhitelistRepository = adminWhitelistRepository;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public Mono<Map<String, Object>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "false") boolean activeOnly) {
        return requireAdmin()
                .then(Mono.zip(
                        dishLibraryService.findAll(page, size, activeOnly).collectList(),
                        dishLibraryService.count(activeOnly)
                ))
                .map(tuple -> Map.of(
                        "content", tuple.getT1(),
                        "total", tuple.getT2(),
                        "page", page,
                        "size", size
                ));
    }

    @GetMapping("/{id}")
    public Mono<DishLibraryResponse> getById(@PathVariable Long id) {
        return requireAdmin()
                .then(dishLibraryService.findById(id))
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<DishLibraryResponse> create(@RequestBody DishLibraryRequest request) {
        return requireAdmin().then(dishLibraryService.create(request));
    }

    @PutMapping("/{id}")
    public Mono<DishLibraryResponse> update(@PathVariable Long id, @RequestBody DishLibraryRequest request) {
        return requireAdmin()
                .then(dishLibraryService.update(id, request))
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @PatchMapping("/{id}/status")
    public Mono<DishLibraryResponse> updateStatus(@PathVariable Long id, @RequestBody Map<String, Boolean> body) {
        boolean isActive = Boolean.TRUE.equals(body.get("isActive"));
        return requireAdmin()
                .then(dishLibraryService.updateStatus(id, isActive))
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable Long id) {
        return requireAdmin().then(dishLibraryService.delete(id));
    }

    private Mono<Void> requireAdmin() {
        return currentUserService.currentUserId()
                .flatMap(userId -> adminWhitelistRepository.findByUserId(userId)
                        .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.FORBIDDEN)))
                        .then());
    }
}
