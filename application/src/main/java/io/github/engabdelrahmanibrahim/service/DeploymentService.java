package io.github.engabdelrahmanibrahim.service;

import io.github.engabdelrahmanibrahim.domain.Deployment;
import io.github.engabdelrahmanibrahim.domain.Environment;
import io.github.engabdelrahmanibrahim.repo.DeploymentRepository;
import io.github.engabdelrahmanibrahim.web.dto.DeploymentRequest;
import io.github.engabdelrahmanibrahim.web.mapper.DeploymentMapper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
public class DeploymentService {
    private final DeploymentRepository repository;

    public DeploymentService(DeploymentRepository repository) {
        this.repository = repository;
    }

    public Page<Deployment> list(Environment env, Pageable pageable) {
        return (env == null)
                ? repository.findAll(pageable)
                : repository.findByEnvironment(env, pageable);
    }

    public Deployment get(Long id) {
        return repository.findById(id)
          .orElseThrow(() -> new IllegalArgumentException("Deployment not found: " + id));
    }

    public Deployment create(DeploymentRequest req) {
        Deployment d = DeploymentMapper.toEntity(req);
        return repository.save(d);
    }

    public Deployment update(Long id, DeploymentRequest req) {
        Deployment d = get(id);
        DeploymentMapper.updateEntity(d, req);
        return repository.save(d);
    }

    public void delete(Long id) {
        if (!repository.existsById(id)) {
            throw new IllegalArgumentException("Deployment not found: " + id);
        }
        repository.deleteById(id);
    }
}
