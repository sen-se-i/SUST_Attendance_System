package com.jarvisatt.attendance.crypto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jarvisatt.attendance.config.CryptoProperties;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AesPayloadCipherTest {
    private final AesPayloadCipher cipher;

    AesPayloadCipherTest() throws Exception {
        cipher = new AesPayloadCipher(new CryptoProperties("test-hmac-secret", "test-aes-key"), new ObjectMapper());
    }

    @Test
    void roundTripsPayload() {
        TickPayload payload = new TickPayload(UUID.randomUUID(), 2, "nonce");
        assertThat(cipher.decrypt(cipher.encrypt(payload))).isEqualTo(payload);
    }

    @Test
    void rejectsTamperedPayload() {
        String encrypted = cipher.encrypt(new TickPayload(UUID.randomUUID(), 1, "nonce"));
        char replacement = encrypted.charAt(5) == 'A' ? 'B' : 'A';
        String tampered = encrypted.substring(0, 5) + replacement + encrypted.substring(6);
        assertThatThrownBy(() -> cipher.decrypt(tampered)).isInstanceOf(IllegalArgumentException.class);
    }
}
