package com.jarvisatt.attendance.crypto;

import com.jarvisatt.attendance.config.CryptoProperties;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class HmacTokenServiceTest {
    @Test
    void tokenAndHashAreStableForSameInputs() {
        HmacTokenService service = new HmacTokenService(new CryptoProperties("same-secret", "aes"));
        UUID sessionId = UUID.randomUUID();
        String token = service.token(sessionId, 1, "nonce");
        assertThat(service.token(sessionId, 1, "nonce")).isEqualTo(token);
        assertThat(service.hash(token)).hasSize(64);
    }
}
