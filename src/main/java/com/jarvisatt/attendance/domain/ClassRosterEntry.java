package com.jarvisatt.attendance.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "class_roster")
@IdClass(ClassRosterEntry.RosterId.class)
public class ClassRosterEntry {
    @Id
    @Column(name = "class_id")
    private UUID classId;

    @Id
    @Column(name = "registration_no")
    private String registrationNo;

    public ClassRosterEntry(UUID classId, String registrationNo) {
        this.classId = classId;
        this.registrationNo = registrationNo;
    }

    public record RosterId(UUID classId, String registrationNo) implements Serializable {}
}
