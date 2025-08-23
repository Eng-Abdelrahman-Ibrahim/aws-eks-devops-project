package io.github.engabdelrahmanibrahim.web;

import io.github.engabdelrahmanibrahim.domain.Deployment;
import io.github.engabdelrahmanibrahim.domain.Environment;
import io.github.engabdelrahmanibrahim.service.DeploymentService;
import io.github.engabdelrahmanibrahim.web.dto.DeploymentRequest;
import io.github.engabdelrahmanibrahim.web.dto.DeploymentResponse;
import io.github.engabdelrahmanibrahim.web.mapper.DeploymentMapper;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api")
public class DashboardController {
    private final DeploymentService service;

    public DashboardController(DeploymentService service) {
        this.service = service;
    }

    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok(
            java.util.Map.of("status", "OK", "timestamp", Instant.now().toString())
        );
    }

    @GetMapping("/deployments")
    public Page<DeploymentResponse> list(
            @RequestParam(value = "env", required = false) Environment env,
            Pageable pageable) {
        return service.list(env, pageable).map(DeploymentMapper::toResponse);
    }

    @GetMapping("/deployments/{id}")
    public DeploymentResponse get(@PathVariable Long id) {
        Deployment d = service.get(id);
        return DeploymentMapper.toResponse(d);
    }

    @PostMapping("/deployments")
    public ResponseEntity<DeploymentResponse> create(@Valid @RequestBody DeploymentRequest req) {
        Deployment saved = service.create(req);
        return ResponseEntity.ok(DeploymentMapper.toResponse(saved));
    }

    @PutMapping("/deployments/{id}")
    public DeploymentResponse update(@PathVariable Long id, @Valid @RequestBody DeploymentRequest req) {
        Deployment saved = service.update(id, req);
        return DeploymentMapper.toResponse(saved);
    }

    @DeleteMapping("/deployments/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

}
