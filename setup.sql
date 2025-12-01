CREATE TYPE user_role_type AS ENUM ('admin', 'methodist', 'teacher', 'student');
CREATE TYPE course_status_type AS ENUM ('draft', 'review', 'certified', 'archived', 'rework');
CREATE TYPE funding_type AS ENUM ('budget', 'contract');
CREATE TYPE task_type AS ENUM ('quiz', 'file_upload', 'forum', 'offline');
CREATE TYPE enrollment_status_type AS ENUM ('active', 'completed', 'dropped', 'failed');

CREATE TABLE faculties (
    faculty_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    short_name VARCHAR(50) NOT NULL
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    faculty_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50) NOT NULL,
    FOREIGN KEY (faculty_id) REFERENCES faculties(faculty_id) ON DELETE CASCADE
);

CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role user_role_type NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE groups (
    group_id SERIAL PRIMARY KEY,
    dept_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    entry_year INT NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE students (
    user_id BIGINT PRIMARY KEY,
    group_id INT NOT NULL,
    student_ticket_number VARCHAR(50) NOT NULL UNIQUE,
    funding funding_type NOT NULL DEFAULT 'budget',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(group_id)
);

CREATE TABLE teachers (
    user_id BIGINT PRIMARY KEY,
    dept_id INT NOT NULL,
    academic_degree VARCHAR(100),
    position VARCHAR(100) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE disciplines (
    discipline_id SERIAL PRIMARY KEY,
    dept_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE courses (
    course_id BIGSERIAL PRIMARY KEY,
    discipline_id INT NOT NULL,
    author_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    credits_ects NUMERIC(3, 1) CHECK (credits_ects > 0 AND credits_ects <= 60),
    status course_status_type DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (discipline_id) REFERENCES disciplines(discipline_id),
    FOREIGN KEY (author_id) REFERENCES teachers(user_id)
);

CREATE TABLE certifications (
    cert_id SERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL,
    protocol_number VARCHAR(100) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    methodist_id BIGINT,
    CHECK (expiry_date > issue_date),
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (methodist_id) REFERENCES users(user_id)
);

CREATE TABLE semesters (
    semester_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE
);

CREATE TABLE course_offerings (
    offering_id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL,
    semester_id INT NOT NULL,
    lead_teacher_id BIGINT NOT NULL,
    max_students INT DEFAULT 100,
    is_open_for_enrollment BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    FOREIGN KEY (lead_teacher_id) REFERENCES teachers(user_id),
    UNIQUE (course_id, semester_id)
);

CREATE TABLE enrollments (
    enrollment_id BIGSERIAL PRIMARY KEY,
    offering_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    final_grade NUMERIC(5, 2) DEFAULT 0 CHECK (final_grade >= 0 AND final_grade <= 100),
    status enrollment_status_type DEFAULT 'active',
    FOREIGN KEY (offering_id) REFERENCES course_offerings(offering_id),
    FOREIGN KEY (student_id) REFERENCES students(user_id),
    UNIQUE (offering_id, student_id)
);

CREATE TABLE assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    max_points INT NOT NULL CHECK (max_points > 0),
    type task_type NOT NULL DEFAULT 'file_upload',
    deadline TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);

CREATE TABLE submissions (
    submission_id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    file_path VARCHAR(500),
    grade_points NUMERIC(5, 2) CHECK (grade_points >= 0),
    teacher_comment TEXT,
    graded_at TIMESTAMP,
    graded_by BIGINT,
    FOREIGN KEY (assignment_id) REFERENCES assignments(assignment_id),
    FOREIGN KEY (student_id) REFERENCES students(user_id),
    FOREIGN KEY (graded_by) REFERENCES teachers(user_id),
    UNIQUE (assignment_id, student_id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_students_group ON students(group_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_submissions_assignment ON submissions(assignment_id);