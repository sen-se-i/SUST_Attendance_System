package com.jarvisatt.attendance.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "jarvis.crypto")
public record CryptoProperties(String hmacSecret, String aesKey) {}
