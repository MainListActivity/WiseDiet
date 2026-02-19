package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.service.DishLibraryService;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

@Controller
@RequestMapping("/admin/ui")
public class AdminUiController {

    private final DishLibraryService dishLibraryService;
    private final JwtService jwtService;
    private final SessionStore sessionStore;
    private final AdminWhitelistRepository adminWhitelistRepository;

    public AdminUiController(DishLibraryService dishLibraryService,
                              JwtService jwtService,
                              SessionStore sessionStore,
                              AdminWhitelistRepository adminWhitelistRepository) {
        this.dishLibraryService = dishLibraryService;
        this.jwtService = jwtService;
        this.sessionStore = sessionStore;
        this.adminWhitelistRepository = adminWhitelistRepository;
    }

    @GetMapping("/dishes")
    public Mono<String> dishList(@RequestParam String token,
                                  @RequestParam(defaultValue = "0") int page,
                                  Model model) {
        return validateAdminToken(token)
                .then(dishLibraryService.findAll(page, 20, false).collectList()
                        .zipWith(dishLibraryService.count(false)))
                .doOnNext(tuple -> {
                    model.addAttribute("dishes", tuple.getT1());
                    model.addAttribute("total", tuple.getT2());
                    model.addAttribute("page", page);
                    model.addAttribute("token", token);
                })
                .thenReturn("admin/dishes");
    }

    @GetMapping("/dishes/new")
    public Mono<String> newForm(@RequestParam String token, Model model) {
        return validateAdminToken(token)
                .doOnSuccess(v -> model.addAttribute("token", token))
                .thenReturn("admin/dish-form");
    }

    @PostMapping("/dishes")
    public Mono<String> create(@RequestParam String token,
                                @ModelAttribute DishFormData form,
                                Model model) {
        return validateAdminToken(token)
                .then(dishLibraryService.create(form.toRequest()))
                .then(dishLibraryService.findAll(0, 20, false).collectList()
                        .zipWith(dishLibraryService.count(false)))
                .doOnNext(tuple -> {
                    model.addAttribute("dishes", tuple.getT1());
                    model.addAttribute("total", tuple.getT2());
                    model.addAttribute("page", 0);
                    model.addAttribute("token", token);
                })
                .thenReturn("admin/dishes :: #dish-list");
    }

    @PostMapping("/dishes/{id}/toggle")
    public Mono<String> toggleStatus(@PathVariable Long id,
                                      @RequestParam String token,
                                      Model model) {
        return validateAdminToken(token)
                .then(dishLibraryService.findById(id))
                .flatMap(dish -> dishLibraryService.updateStatus(id, !dish.isActive()))
                .doOnNext(updated -> {
                    model.addAttribute("dish", updated);
                    model.addAttribute("token", token);
                })
                .thenReturn("admin/dishes :: .dish-row-" + id);
    }

    private Mono<Void> validateAdminToken(String token) {
        return Mono.fromCallable(() -> jwtService.extractJti(token))
                .onErrorMap(e -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token"))
                .flatMap(jti -> sessionStore.exists(jti)
                        .flatMap(exists -> {
                            if (!exists) return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Session expired"));
                            return jwtService.parseUserId(token);
                        }))
                .flatMap(userId -> adminWhitelistRepository.existsByUserId(userId)
                        .filter(Boolean.TRUE::equals)
                        .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.FORBIDDEN, "Not admin")))
                        .then());
    }
}
