class SubjectItem {
  final String code;
  final String name;
  final double credits;

  const SubjectItem({
    required this.code,
    required this.name,
    required this.credits,
  });
}

class SubjectCatalog {
  static const List<String> departments = [
    'Software Engineering',
    'Computer Science and Engineering',
    'Electrical and Electronics Engineering',
  ];

  static const List<String> semesters = [
    'Year 1 Semester 1',
    'Year 1 Semester 2',
    'Year 2 Semester 1',
    'Year 2 Semester 2',
    'Year 3 Semester 1',
    'Year 3 Semester 2',
    'Year 4 Semester 1',
    'Year 4 Semester 2',
  ];

  static const Map<String, List<SubjectItem>> sweCurriculum = {
    'Year 1 Semester 1': [
      SubjectItem(code: 'SWE0613-1121', name: 'Structured Programming Language', credits: 3.0),
      SubjectItem(code: 'SWE0613-1122', name: 'Structured Programming Language Lab', credits: 1.5),
      SubjectItem(code: 'SWE0541-1123', name: 'Discrete Mathematics', credits: 3.0),
      SubjectItem(code: 'EEE0712-1101W', name: 'Basic Electrical and Electronic Circuits', credits: 3.0),
      SubjectItem(code: 'EEE0712-1102W', name: 'Basic Electrical and Electronic Circuits Lab', credits: 1.5),
      SubjectItem(code: 'MAT0541-1105W', name: 'Coordinate Geometry and Calculus', credits: 3.0),
      SubjectItem(code: 'ENG0231-1101W', name: 'Effective Communication in English', credits: 2.0),
      SubjectItem(code: 'ENG0231-1102W', name: 'English Language Lab 1', credits: 1.0),
    ],
    'Year 1 Semester 2': [
      SubjectItem(code: 'SWE0613-1225', name: 'Introduction to Software Engineering', credits: 3.0),
      SubjectItem(code: 'SWE0613-1227', name: 'Data Structure', credits: 3.0),
      SubjectItem(code: 'SWE0613-1228', name: 'Data Structure Lab', credits: 2.0),
      SubjectItem(code: 'PHY0533-1203W', name: 'Mechanics, Wave, Heat & Thermodynamics', credits: 3.0),
      SubjectItem(code: 'MAT0541-1207W', name: 'Linear and Abstract Algebra', credits: 3.0),
      SubjectItem(code: 'STA0542-1201W', name: 'Basic Statistics', credits: 3.0),
      SubjectItem(code: 'SOC0314-1203W', name: 'Sociology for Engineers', credits: 3.0),
      SubjectItem(code: 'SWE0610-1250', name: 'Project Work-I', credits: 2.0),
    ],
    'Year 2 Semester 1': [
      SubjectItem(code: 'SWE0613-2122', name: 'Introduction to Competitive Programming', credits: 2.0),
      SubjectItem(code: 'SWE0613-2123', name: 'Object Oriented Programming', credits: 3.0),
      SubjectItem(code: 'SWE0613-2124', name: 'Object Oriented Programming Language Lab', credits: 2.0),
      SubjectItem(code: 'SWE0613-2125', name: 'Software Requirement Engineering', credits: 2.0),
      SubjectItem(code: 'SWE0613-2126', name: 'Software Requirement Engineering Lab', credits: 1.5),
      SubjectItem(code: 'CSE0613-2119W', name: 'Computer Architecture', credits: 3.0),
      SubjectItem(code: 'STA0542-2101W', name: 'Probability and Probability Function', credits: 3.0),
      SubjectItem(code: 'BUS0411-2101W', name: 'Cost and Management Accounting', credits: 3.0),
      SubjectItem(code: 'ECO0311-2105W', name: 'Principles of Economics', credits: 3.0),
    ],
    'Year 2 Semester 2': [
      SubjectItem(code: 'SWE0613-2227', name: 'Theory of Computation', credits: 2.0),
      SubjectItem(code: 'SWE0613-2229', name: 'Algorithm Design & Analysis', credits: 3.0),
      SubjectItem(code: 'SWE0613-2230', name: 'Algorithm Design & Analysis Lab', credits: 1.5),
      SubjectItem(code: 'SWE0541-2231', name: 'Numerical Analysis', credits: 2.0),
      SubjectItem(code: 'SWE0541-2232', name: 'Numerical Analysis Lab', credits: 1.5),
      SubjectItem(code: 'SWE0613-2233', name: 'Operating Systems and System Programming', credits: 3.0),
      SubjectItem(code: 'SWE0613-2234', name: 'Operating Systems and System Programming Lab', credits: 1.5),
      SubjectItem(code: 'SWE0488-2235', name: 'Ethics and Cyber Law', credits: 2.0),
      SubjectItem(code: 'SWE0688-2237', name: 'Management Information System', credits: 2.0),
      SubjectItem(code: 'SWE0610-2250', name: 'Project Work –II', credits: 2.0),
    ],
    'Year 3 Semester 1': [
      SubjectItem(code: 'SWE0613-3121', name: 'Software Architecture and Design Patterns', credits: 3.0),
      SubjectItem(code: 'SWE0613-3122', name: 'Software Architecture and Design Patterns Lab', credits: 1.5),
      SubjectItem(code: 'SWE0619-3123', name: 'Artificial Intelligence', credits: 3.0),
      SubjectItem(code: 'SWE0619-3124', name: 'Artificial Intelligence Lab', credits: 1.5),
      SubjectItem(code: 'SWE0612-3127', name: 'Database Management System', credits: 3.0),
      SubjectItem(code: 'SWE0612-3128', name: 'Database Management System Lab', credits: 2.0),
      SubjectItem(code: 'SWE0612-3130', name: 'Web Technologies', credits: 2.0),
      SubjectItem(code: 'CSE0612-3113W', name: 'Computer Networking', credits: 3.0),
      SubjectItem(code: 'CSE0612-3114W', name: 'Computer Networking Lab', credits: 1.5),
    ],
    'Year 3 Semester 2': [
      SubjectItem(code: 'SWE0612-3225', name: 'Distributed System', credits: 2.0),
      SubjectItem(code: 'SWE0612-3226', name: 'Distributed System Lab', credits: 1.5),
      SubjectItem(code: 'SWE0613-3231', name: 'Software Usability and Metrics', credits: 2.0),
      SubjectItem(code: 'SWE0613-3233', name: 'Software Verification and Validation', credits: 2.0),
      SubjectItem(code: 'SWE0613-3234', name: 'Software Verification and Validation Lab', credits: 1.5),
      SubjectItem(code: 'SWE0611-3242', name: 'Technical Writing And Presentation', credits: 2.0),
      SubjectItem(code: 'SWE0619-3243', name: 'Machine Learning', credits: 3.0),
      SubjectItem(code: 'SWE0619-3244', name: 'Machine Learning Lab', credits: 1.5),
      SubjectItem(code: 'BUS0414-3201W', name: 'Entrepreneurship Development', credits: 2.0),
      SubjectItem(code: 'SWE0610-3250', name: 'Project Work-III', credits: 2.0),
    ],
    'Year 4 Semester 1': [
      SubjectItem(code: 'SWE0613-4125', name: 'Software Project Management', credits: 2.0),
      SubjectItem(code: 'SWE0613-4126', name: 'Software Project Management Lab', credits: 1.0),
      SubjectItem(code: 'SWE0612-4129', name: 'Information and Network Security', credits: 2.0),
      SubjectItem(code: 'SWE0612-4130', name: 'Information and Network Security Lab', credits: 1.5),
      SubjectItem(code: 'SWE0688-4131', name: 'Human Computer Interaction', credits: 3.0),
      SubjectItem(code: 'SWE0688-4132', name: 'Human Computer Interaction Lab', credits: 1.5),
      SubjectItem(code: 'SWE0610-4150', name: 'Thesis/Project', credits: 4.0),
      SubjectItem(code: 'SWE0613-4123', name: 'Computer Graphics and Image Processing', credits: 3.0),
      SubjectItem(code: 'SWE0613-4133', name: 'Advanced Data Structure and Algorithm', credits: 3.0),
      SubjectItem(code: 'SWE0619-4135', name: 'Neural Network and Deep Learning', credits: 3.0),
      SubjectItem(code: 'SWE0612-4136', name: 'Advanced Database System', credits: 3.0),
      SubjectItem(code: 'SWE0688-4139', name: 'Bioinformatics', credits: 3.0),
      SubjectItem(code: 'SWE0613-4141', name: 'Natural Language Processing', credits: 3.0),
      SubjectItem(code: 'SWE0612-4143', name: 'Cloud Computing', credits: 3.0),
      SubjectItem(code: 'SWE0613-4151', name: 'Introduction to DevOps', credits: 3.0),
      SubjectItem(code: 'SWE0612-4153', name: 'Introduction to Cryptography', credits: 3.0),
      SubjectItem(code: 'SWE0688-4155', name: 'Applied Data Science', credits: 3.0),
    ],
    'Year 4 Semester 2': [
      SubjectItem(code: 'SWE0613-4220', name: 'Internship', credits: 18.0),
      SubjectItem(code: 'SWE0610-4160', name: 'Comprehensive Viva Voce', credits: 1.0),
    ],
  };

  static List<SubjectItem> getSubjects(String department, String semester) {
    if (department == 'Software Engineering') {
      return sweCurriculum[semester] ?? [];
    }
    return [];
  }
}
