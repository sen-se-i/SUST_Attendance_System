package com.jarvisatt.attendance.service.notification;

import com.jarvisatt.attendance.domain.AttendanceRecord;

public interface NotificationService {
    void attendanceConfirmed(AttendanceRecord record);
}
