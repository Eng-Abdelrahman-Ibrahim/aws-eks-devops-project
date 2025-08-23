package io.github.engabdelrahmanibrahim.domain;

import jakarta.persistence.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;

@Entity
@Table(name = "deployments")
@EntityListeners(AuditingEntityListener.class)
public class Deployment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String version;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Environment environment;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private boolean success;

    @Column(length = 500)
    private String notes;

    // getters/setters
    public Long getId() { return id; }
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public Environment getEnvironment() { return environment; }
    public void setEnvironment(Environment environment) { this.environment = environment; }
    public Instant getCreatedAt() { return createdAt; }
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
