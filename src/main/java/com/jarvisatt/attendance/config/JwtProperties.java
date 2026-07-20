package com.jarvisatt.attendance.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(prefix = "jarvis.jwt")
public record JwtProperties(String secret, Duration ttl) {}
