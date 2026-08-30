package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.repository.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class AttendanceExportService {
    private final ClassService classService;
    private final EnrollmentRepository enrollmentRepository;
    private final ClassSessionRepository classSessionRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd hh:mm a");

    @Transactional(readOnly = true)
    public MatrixReportResponse generateMatrixReport(UUID classId, UserPrincipal principal) {
        ClassEntity classEntity = classService.ownedClass(classId, principal);

        List<ClassSession> sessions = classSessionRepository.findByClassEntityIdOrderByStartedAtAsc(classId);

        List<Enrollment> enrollments = enrollmentRepository.findByClassEntityIdAndStatus(classId, EnrollmentStatus.ACTIVE);
        List<User> students = enrollments.stream()
                .map(Enrollment::getStudent)
                .sorted(Comparator.comparing(User::getRegistrationNo, Comparator.nullsLast(String::compareTo)))
                .toList();

        List<AttendanceRecord> records = attendanceRecordRepository.findByClassEntityId(classId);

        Set<String> attendanceSet = new HashSet<>();
        for (AttendanceRecord r : records) {
            attendanceSet.add(r.getSession().getId() + "_" + r.getRegistrationNo());
        }

        List<SessionColumn> sessionColumns = new ArrayList<>();
        List<Integer> sessionAttendanceCounts = new ArrayList<>();

        for (ClassSession s : sessions) {
            long count = records.stream().filter(r -> r.getSession().getId().equals(s.getId())).count();
            sessionColumns.add(new SessionColumn(s.getId(), s.getStartedAt(), (int) count));
            sessionAttendanceCounts.add((int) count);
        }

        List<StudentRow> studentRows = new ArrayList<>();
        int totalSessions = sessions.size();
        double sumPercentages = 0.0;

        for (User st : students) {
            String reg = st.getRegistrationNo();
            List<Boolean> attendanceList = new ArrayList<>();
            int attendedCount = 0;

            for (ClassSession s : sessions) {
                boolean present = attendanceSet.contains(s.getId() + "_" + reg);
                attendanceList.add(present);
                if (present) attendedCount++;
            }

            double pct = totalSessions > 0 ? (attendedCount * 100.0 / totalSessions) : 0.0;

            pct = Math.round(pct * 10.0) / 10.0;
            sumPercentages += pct;
            String mark = StudentRow.computeMark(pct);

            studentRows.add(new StudentRow(reg, attendanceList, attendedCount, pct, mark));
        }

        double avgPercentage = !students.isEmpty() ? (sumPercentages / students.size()) : 0.0;
        avgPercentage = Math.round(avgPercentage * 10.0) / 10.0;

        String teacherName = classEntity.getTeacher() != null ? classEntity.getTeacher().getEmail() : "Faculty";

        return new MatrixReportResponse(
                classEntity.getId(),
                classEntity.getCode(),
                classEntity.getSubjectName(),
                classEntity.getSubjectCode(),
                classEntity.getDepartment(),
                classEntity.getAcademicSession(),
                classEntity.getSemester(),
                teacherName,
                totalSessions,
                students.size(),
                avgPercentage,
                sessionColumns,
                studentRows,
                sessionAttendanceCounts
        );
    }

    @Transactional(readOnly = true)
    public String generateCsv(UUID classId, UserPrincipal principal) {
        MatrixReportResponse matrix = generateMatrixReport(classId, principal);
        StringBuilder sb = new StringBuilder();

        sb.append("\"Class Code:\",\"").append(matrix.classCode()).append("\",\"Subject:\",\"")
                .append(matrix.subjectName() != null ? matrix.subjectName() : matrix.subjectCode()).append("\"\n");
        sb.append("\"Department:\",\"").append(matrix.department()).append("\",\"Session:\",\"")
                .append(matrix.academicSession()).append("\"\n");
        sb.append("\"Total Sessions:\",").append(matrix.totalSessions()).append(",\"Total Students:\",")
                .append(matrix.totalStudents()).append(",\"Average Attendance:\",\"")
                .append(matrix.averageAttendancePercentage()).append("%\"\n\n");

        sb.append("\"Registration No\"");
        for (SessionColumn col : matrix.sessions()) {
            String formattedDate = col.startedAt() != null ? col.startedAt().format(DATE_TIME_FORMATTER) : "Session";
            sb.append(",\"").append(formattedDate).append("\"");
        }
        sb.append(",\"Total Attended\",\"Attendance (%)\",\"Attendance Marks\"\n");

        for (StudentRow row : matrix.studentRows()) {
            sb.append("\"").append(row.registrationNo()).append("\"");
            for (Boolean present : row.attendance()) {
                sb.append(",\"").append(Boolean.TRUE.equals(present) ? "P" : "A").append("\"");
            }
            sb.append(",").append(row.totalAttended())
              .append(",\"").append(row.percentage()).append("%\"")
              .append(",\"").append(row.attendanceMark()).append("\"\n");
        }

        sb.append("\"Total Present\"");
        for (Integer count : matrix.sessionAttendanceCounts()) {
            sb.append(",").append(count);
        }
        sb.append(",,\n");

        sb.append("\n");
        sb.append("\"ATTENDANCE MARKS POLICY\"\n");
        sb.append("\"95-100%\",\"10 marks\"\n");
        sb.append("\"90-94%\",\"9 marks\"\n");
        sb.append("\"85-89%\",\"8 marks\"\n");
        sb.append("\"80-84%\",\"7 marks\"\n");
        sb.append("\"75-79%\",\"6 marks\"\n");
        sb.append("\"70-74%\",\"5 marks\"\n");
        sb.append("\"65-69%\",\"4 marks\"\n");
        sb.append("\"60-64%\",\"3 marks\"\n");
        sb.append("\"50-59%\",\"0 marks (Exam Eligible)\"\n");
        sb.append("\"0-49%\",\"INELIGIBLE for Exam\"\n");

        return sb.toString();
    }
}
