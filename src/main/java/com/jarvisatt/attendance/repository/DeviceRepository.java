package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.Device;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface DeviceRepository extends JpaRepository<Device, UUID> {
    Optional<Device> findByInstallId(String installId);
}
