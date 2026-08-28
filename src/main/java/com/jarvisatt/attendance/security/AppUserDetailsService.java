package com.jarvisatt.attendance.security;

import com.jarvisatt.attendance.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService {
    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        if (username == null || username.isBlank()) {
            throw new UsernameNotFoundException("Username is null or blank");
        }
        String clean = username.trim();
        return userRepository.findByEmail(clean.toLowerCase())
                .or(() -> userRepository.findByRegistrationNo(clean))
                .or(() -> {
                    try {
                        return userRepository.findById(UUID.fromString(clean));
                    } catch (Exception e) {
                        return Optional.empty();
                    }
                })
                .map(UserPrincipal::from)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }
}
