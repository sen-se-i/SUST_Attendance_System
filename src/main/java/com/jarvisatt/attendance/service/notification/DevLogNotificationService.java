package com.jarvisatt.attendance.service.notification;

import com.jarvisatt.attendance.domain.AttendanceRecord;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class DevLogNotificationService implements NotificationService {
    @Override
    public void attendanceConfirmed(AttendanceRecord record) {
        log.info("attendance.confirmed registrationNo={} sessionId={} scannedAt={}",
                record.getRegistrationNo(), record.getSession().getId(), record.getScannedAt());
    }
}
