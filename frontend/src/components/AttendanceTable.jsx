export function AttendanceTable({ rows, emptyLabel, showSubject = false, showRegistration = false }) {
  if (!rows.length) return <p className="empty-state">{emptyLabel}</p>;

  return (
    <div className="custom-table-container">
      <table className="custom-table">
        <thead>
          <tr>
            {showSubject && <th>Class</th>}
            {showRegistration && <th>Registration No</th>}
            <th>Scanned At</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              {showSubject && <td>{row.subjectCode || "Class"}</td>}
              {showRegistration && <td>{row.registrationNo}</td>}
              <td>{new Date(row.scannedAt).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
