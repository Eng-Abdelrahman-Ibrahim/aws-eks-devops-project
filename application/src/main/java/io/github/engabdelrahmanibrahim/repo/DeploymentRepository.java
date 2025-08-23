package io.github.engabdelrahmanibrahim.repo;

import io.github.engabdelrahmanibrahim.domain.Deployment;
import io.github.engabdelrahmanibrahim.domain.Environment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeploymentRepository extends JpaRepository<Deployment, Long> {
    Page<Deployment> findByEnvironment(Environment env, Pageable pageable);
}
