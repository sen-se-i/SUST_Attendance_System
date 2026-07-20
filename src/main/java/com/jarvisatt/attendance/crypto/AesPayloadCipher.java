package com.jarvisatt.attendance.crypto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jarvisatt.attendance.config.CryptoProperties;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

@Service
public class AesPayloadCipher {
    private static final int IV_BYTES = 12;
    private static final int TAG_BITS = 128;
    private final ObjectMapper objectMapper;
    private final SecretKeySpec key;
    private final SecureRandom secureRandom = new SecureRandom();

    public AesPayloadCipher(CryptoProperties properties, ObjectMapper objectMapper) throws Exception {
        this.objectMapper = objectMapper;
        byte[] keyBytes = MessageDigest.getInstance("SHA-256").digest(properties.aesKey().getBytes(StandardCharsets.UTF_8));
        this.key = new SecretKeySpec(keyBytes, "AES");
    }

    public String encrypt(TickPayload payload) {
        try {
            byte[] iv = new byte[IV_BYTES];
            secureRandom.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, iv));
            byte[] encrypted = cipher.doFinal(objectMapper.writeValueAsBytes(payload));
            byte[] out = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, out, 0, iv.length);
            System.arraycopy(encrypted, 0, out, iv.length, encrypted.length);
            return Base64.getUrlEncoder().withoutPadding().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalArgumentException("Could not encrypt QR payload", e);
        }
    }

    public TickPayload decrypt(String encoded) {
        try {
            byte[] input = Base64.getUrlDecoder().decode(encoded);
            byte[] iv = Arrays.copyOfRange(input, 0, IV_BYTES);
            byte[] encrypted = Arrays.copyOfRange(input, IV_BYTES, input.length);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, iv));
            return objectMapper.readValue(cipher.doFinal(encrypted), TickPayload.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid QR payload");
        }
    }
}
