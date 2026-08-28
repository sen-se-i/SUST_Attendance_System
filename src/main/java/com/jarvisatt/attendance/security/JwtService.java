package com.jarvisatt.attendance.security;

import com.jarvisatt.attendance.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

@Service
public class JwtService {
    private final JwtProperties properties;
    private final SecretKey key;

    public JwtService(JwtProperties properties) {
        this.properties = properties;
        this.key = Keys.hmacShaKeyFor(properties.secret().getBytes(StandardCharsets.UTF_8));
    }

    public String issue(UserPrincipal principal) {
        Instant now = Instant.now();
        String subject = principal.email() != null && !principal.email().isBlank()
                ? principal.email().trim().toLowerCase()
                : (principal.registrationNo() != null && !principal.registrationNo().isBlank()
                    ? principal.registrationNo().trim()
                    : principal.id().toString());

        return Jwts.builder()
                .subject(subject)
                .claim("uid", principal.id().toString())
                .claim("role", principal.role().name())
                .claim("reg", principal.registrationNo())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(properties.ttl())))
                .signWith(key)
                .compact();
    }

    public String subject(String token) {
        return claims(token).getSubject();
    }

    public String getUserId(String token) {
        Object uid = claims(token).get("uid");
        return uid != null ? uid.toString() : null;
    }

    private Claims claims(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
