package com.jarvisatt.attendance.crypto;

import com.jarvisatt.attendance.config.CryptoProperties;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class HmacTokenService {
    private final byte[] secret;
    private final SecureRandom secureRandom = new SecureRandom();

    public HmacTokenService(CryptoProperties properties) {
        this.secret = properties.hmacSecret().getBytes(StandardCharsets.UTF_8);
    }

    public String nonce() {
        byte[] bytes = new byte[24];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String token(UUID sessionId, int tickIndex, String nonce) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal((sessionId + ":" + tickIndex + ":" + nonce).getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Could not create QR token", e);
        }
    }

    public String hash(String token) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Could not hash QR token", e);
        }
    }
}
