package io.github.engabdelrahmanibrahim.web.dto;

import io.github.engabdelrahmanibrahim.domain.Environment;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class DeploymentRequest {
    @NotBlank @Size(max = 100)
    private String version;

    @NotNull
    private Environment environment;

    @NotNull
    private boolean success;

    @Size(max = 500)
    private String notes;

    // getters/setters
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public Environment getEnvironment() { return environment; }
    public void setEnvironment(Environment environment) { this.environment = environment; }
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
