package io.github.engabdelrahmanibrahim.web.dto;

import io.github.engabdelrahmanibrahim.domain.Environment;

import java.time.Instant;

public class DeploymentResponse {
    private Long id;
    private String version;
    private Environment environment;
    private boolean success;
    private String notes;
    private Instant createdAt;

    // getters/setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public Environment getEnvironment() { return environment; }
    public void setEnvironment(Environment environment) { this.environment = environment; }
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
