package io.github.engabdelrahmanibrahim.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {
    
    @GetMapping("/api")
    public String home() {
        return "DevOps Dashboard API is running! Use /api/health or /api/deployments";
    }
}