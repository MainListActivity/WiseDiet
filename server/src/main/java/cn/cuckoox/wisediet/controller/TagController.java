package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.model.OccupationTag;
import cn.cuckoox.wisediet.repository.OccupationTagRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/tags")
public class TagController {

    private final OccupationTagRepository tagRepository;

    public TagController(OccupationTagRepository tagRepository) {
        this.tagRepository = tagRepository;
    }

    @GetMapping("/occupations")
    public Flux<OccupationTag> getAllTags() {
        return tagRepository.findAll();
    }
}
