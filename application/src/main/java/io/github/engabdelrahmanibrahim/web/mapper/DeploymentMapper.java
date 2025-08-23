package io.github.engabdelrahmanibrahim.web.mapper;

import io.github.engabdelrahmanibrahim.domain.Deployment;
import io.github.engabdelrahmanibrahim.web.dto.DeploymentRequest;
import io.github.engabdelrahmanibrahim.web.dto.DeploymentResponse;

public class DeploymentMapper {
    public static Deployment toEntity(DeploymentRequest req) {
        Deployment d = new Deployment();
        d.setVersion(req.getVersion());
        d.setEnvironment(req.getEnvironment());
        d.setSuccess(req.isSuccess());
        d.setNotes(req.getNotes());
        return d;
    }

    public static void updateEntity(Deployment d, DeploymentRequest req) {
        d.setVersion(req.getVersion());
        d.setEnvironment(req.getEnvironment());
        d.setSuccess(req.isSuccess());
        d.setNotes(req.getNotes());
    }

    public static DeploymentResponse toResponse(Deployment d) {
        DeploymentResponse r = new DeploymentResponse();
        r.setId(d.getId());
        r.setVersion(d.getVersion());
        r.setEnvironment(d.getEnvironment());
        r.setSuccess(d.isSuccess());
        r.setNotes(d.getNotes());
        r.setCreatedAt(d.getCreatedAt());
        return r;
    }
}
