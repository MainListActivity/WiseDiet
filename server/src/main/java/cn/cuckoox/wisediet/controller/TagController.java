package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.model.AllergenTag;
import cn.cuckoox.wisediet.model.DietaryPreferenceTag;
import cn.cuckoox.wisediet.model.OccupationTag;
import cn.cuckoox.wisediet.repository.AllergenTagRepository;
import cn.cuckoox.wisediet.repository.DietaryPreferenceTagRepository;
import cn.cuckoox.wisediet.repository.OccupationTagRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/tags")
public class TagController {

    private final OccupationTagRepository tagRepository;
    private final AllergenTagRepository allergenTagRepository;
    private final DietaryPreferenceTagRepository dietaryPreferenceTagRepository;

    public TagController(OccupationTagRepository tagRepository,
                         AllergenTagRepository allergenTagRepository,
                         DietaryPreferenceTagRepository dietaryPreferenceTagRepository) {
        this.tagRepository = tagRepository;
        this.allergenTagRepository = allergenTagRepository;
        this.dietaryPreferenceTagRepository = dietaryPreferenceTagRepository;
    }

    @GetMapping("/occupations")
    public Flux<OccupationTag> getAllTags() {
        return tagRepository.findAll();
    }

    @GetMapping("/allergens")
    public Flux<AllergenTag> getAllAllergenTags() {
        return allergenTagRepository.findAll();
    }

    @GetMapping("/dietary-preferences")
    public Flux<DietaryPreferenceTag> getAllDietaryPreferenceTags() {
        return dietaryPreferenceTagRepository.findAll();
    }
}
