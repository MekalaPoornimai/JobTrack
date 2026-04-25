-- ==============================================================
--  JobTrack – Job/Internship Application Tracking System
--  Central Michigan University (CMU)
--  Database Schema: MySQL 8.0+
--
--  Based on:  ERD · DFD · System Proposal · UI (20 pages)
--  Entities:  User, Student, Advisor, Employer, Admin,
--             Job_Posting, Application, Interview, AdvisingNote
-- ==============================================================

-- -------------------------------------------------------
-- 1. CREATE & SELECT DATABASE
-- -------------------------------------------------------
CREATE DATABASE IF NOT EXISTS jobtrack_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE jobtrack_db;

-- -------------------------------------------------------
-- 2. DROP TABLES (clean slate – safe for re-runs)
-- -------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS advising_notes;
DROP TABLE IF EXISTS interviews;
DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS job_skills;
DROP TABLE IF EXISTS job_postings;
DROP TABLE IF EXISTS student_skills;
DROP TABLE IF EXISTS student_advisor_assignments;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS employers;
DROP TABLE IF EXISTS advisors;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================
--  CORE TABLES
-- ==============================================================

-- -------------------------------------------------------
-- TABLE: users  (unified login – all roles share one table)
--   → Supports single login page (no role selector) per instructor feedback
-- -------------------------------------------------------
CREATE TABLE users (
    user_id       INT          AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,   -- CMU email (xxx@cmich.edu)
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('student','advisor','employer','admin') NOT NULL,
    is_active     BOOLEAN      DEFAULT TRUE,
    created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role  (role)
);

-- -------------------------------------------------------
-- TABLE: students
-- -------------------------------------------------------
CREATE TABLE students (
    student_id       INT          AUTO_INCREMENT PRIMARY KEY,
    user_id          INT          NOT NULL UNIQUE,
    student_number   VARCHAR(20)  UNIQUE,             -- CMU student ID
    major            VARCHAR(100),
    graduation_year  YEAR,
    gpa              DECIMAL(3,2) CHECK (gpa BETWEEN 0.00 AND 4.00),
    phone            VARCHAR(20),
    bio              TEXT,
    resume_url       VARCHAR(500),
    linkedin_url     VARCHAR(500),
    portfolio_url    VARCHAR(500),
    profile_complete BOOLEAN      DEFAULT FALSE,
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- TABLE: advisors
-- -------------------------------------------------------
CREATE TABLE advisors (
    advisor_id      INT          AUTO_INCREMENT PRIMARY KEY,
    user_id         INT          NOT NULL UNIQUE,
    department      VARCHAR(100) DEFAULT 'Career Services',
    office_location VARCHAR(100),
    phone           VARCHAR(20),
    specialization  VARCHAR(200),           -- e.g. Technology & Engineering
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- TABLE: employers
-- -------------------------------------------------------
CREATE TABLE employers (
    employer_id  INT          AUTO_INCREMENT PRIMARY KEY,
    user_id      INT          NOT NULL UNIQUE,
    company_name VARCHAR(200) NOT NULL,
    industry     VARCHAR(100),
    company_size ENUM('1-10','11-50','51-200','201-500','501-1000','1000+'),
    website      VARCHAR(500),
    description  TEXT,
    location     VARCHAR(200),
    logo_url     VARCHAR(500),
    is_verified  BOOLEAN      DEFAULT FALSE,
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- TABLE: admins  (Career Service Administrators)
-- -------------------------------------------------------
CREATE TABLE admins (
    admin_id   INT          AUTO_INCREMENT PRIMARY KEY,
    user_id    INT          NOT NULL UNIQUE,
    department VARCHAR(100) DEFAULT 'Career Services',
    created_at DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ==============================================================
--  LOOKUP / BRIDGE TABLES
-- ==============================================================

-- -------------------------------------------------------
-- TABLE: skills  (shared skill catalogue)
-- -------------------------------------------------------
CREATE TABLE skills (
    skill_id   INT          AUTO_INCREMENT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category   VARCHAR(50)             -- Programming / Analytics / Soft Skills / Tools
);

-- -------------------------------------------------------
-- TABLE: student_skills  (M:M  student ↔ skill)
-- -------------------------------------------------------
CREATE TABLE student_skills (
    student_id INT NOT NULL,
    skill_id   INT NOT NULL,
    PRIMARY KEY (student_id, skill_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id)   REFERENCES skills(skill_id)     ON DELETE CASCADE
);

-- -------------------------------------------------------
-- TABLE: student_advisor_assignments  (M:M  student ↔ advisor)
-- -------------------------------------------------------
CREATE TABLE student_advisor_assignments (
    assignment_id INT      AUTO_INCREMENT PRIMARY KEY,
    student_id    INT      NOT NULL,
    advisor_id    INT      NOT NULL,
    assigned_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active     BOOLEAN  DEFAULT TRUE,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (advisor_id) REFERENCES advisors(advisor_id) ON DELETE CASCADE,
    UNIQUE KEY uq_student_advisor (student_id, advisor_id)
);

-- ==============================================================
--  JOB POSTINGS  (from DFD: Manage Job Postings)
-- ==============================================================
CREATE TABLE job_postings (
    job_id               INT          AUTO_INCREMENT PRIMARY KEY,
    employer_id          INT          NOT NULL,
    title                VARCHAR(200) NOT NULL,
    description          TEXT,
    requirements         TEXT,
    location             VARCHAR(200),
    job_type             ENUM('full-time','part-time','internship','co-op','contract') NOT NULL,
    salary_min           DECIMAL(10,2),
    salary_max           DECIMAL(10,2),
    application_deadline DATE,
    status               ENUM('draft','active','closed','filled') DEFAULT 'active',
    posted_at            DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employer_id) REFERENCES employers(employer_id) ON DELETE CASCADE,
    INDEX idx_status    (status),
    INDEX idx_job_type  (job_type),
    INDEX idx_posted_at (posted_at)
);

-- -------------------------------------------------------
-- TABLE: job_skills  (M:M  job ↔ required skill)
-- -------------------------------------------------------
CREATE TABLE job_skills (
    job_id   INT NOT NULL,
    skill_id INT NOT NULL,
    PRIMARY KEY (job_id, skill_id),
    FOREIGN KEY (job_id)   REFERENCES job_postings(job_id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id)     ON DELETE CASCADE
);

-- ==============================================================
--  APPLICATIONS  (from DFD: Manage Applications)
-- ==============================================================
CREATE TABLE applications (
    application_id INT      AUTO_INCREMENT PRIMARY KEY,
    student_id     INT      NOT NULL,
    job_id         INT      NOT NULL,
    status         ENUM(
                     'applied',
                     'under_review',
                     'interview_scheduled',
                     'offer_extended',
                     'accepted',
                     'rejected',
                     'withdrawn'
                   )        DEFAULT 'applied',
    cover_letter   TEXT,
    student_notes  TEXT,                         -- private notes from student
    applied_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)    ON DELETE CASCADE,
    FOREIGN KEY (job_id)     REFERENCES job_postings(job_id)    ON DELETE CASCADE,
    UNIQUE KEY uq_student_job (student_id, job_id),       -- one app per job
    INDEX idx_status     (status),
    INDEX idx_applied_at (applied_at)
);

-- ==============================================================
--  INTERVIEWS  (from DFD: Track Interviews)
-- ==============================================================
CREATE TABLE interviews (
    interview_id     INT          AUTO_INCREMENT PRIMARY KEY,
    application_id   INT          NOT NULL,
    scheduled_date   DATE         NOT NULL,
    scheduled_time   TIME         NOT NULL,
    interview_type   ENUM('phone','video','in-person','technical','panel') NOT NULL,
    location_or_link VARCHAR(500),               -- room number OR meeting URL
    duration_minutes INT          DEFAULT 60,
    status           ENUM('scheduled','completed','cancelled','rescheduled','no_show')
                                  DEFAULT 'scheduled',
    prep_notes       TEXT,                       -- student interview prep
    feedback_notes   TEXT,                       -- post-interview feedback
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE,
    INDEX idx_scheduled_date (scheduled_date),
    INDEX idx_status         (status)
);

-- ==============================================================
--  ADVISING NOTES  (from DFD: Monitor & Advise)
-- ==============================================================
CREATE TABLE advising_notes (
    note_id      INT      AUTO_INCREMENT PRIMARY KEY,
    advisor_id   INT      NOT NULL,
    student_id   INT      NOT NULL,
    note_content TEXT     NOT NULL,
    note_type    ENUM(
                   'general',
                   'application_advice',
                   'career_goal',
                   'interview_prep',
                   'resume_review',
                   'follow_up'
                 )        DEFAULT 'general',
    is_private   BOOLEAN  DEFAULT FALSE,          -- only advisor can see if TRUE
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (advisor_id) REFERENCES advisors(advisor_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    INDEX idx_advisor  (advisor_id),
    INDEX idx_student  (student_id),
    INDEX idx_note_type (note_type)
);

-- ==============================================================
--  SAMPLE DATA
-- ==============================================================

-- -------------------------------------------------------
-- Users (password_hash = bcrypt placeholder – replace in prod)
-- -------------------------------------------------------
INSERT INTO users (first_name, last_name, email, password_hash, role) VALUES
-- Students
('Jordan',   'Smith',    'smith1js@cmich.edu',      '$2b$10$samplehash_jordan',   'student'),
('Alex',     'Johnson',  'johnson2aj@cmich.edu',    '$2b$10$samplehash_alex',     'student'),
('Maria',    'Garcia',   'garcia3mg@cmich.edu',     '$2b$10$samplehash_maria',    'student'),
('Kevin',    'Patel',    'patel4kp@cmich.edu',      '$2b$10$samplehash_kevin',    'student'),
-- Advisors
('Lisa',     'Chen',     'chen5lc@cmich.edu',       '$2b$10$samplehash_lisa',     'advisor'),
('Mark',     'Williams', 'williams6mw@cmich.edu',   '$2b$10$samplehash_mark',     'advisor'),
-- Employers
('Tech',     'Corp',     'hr@techcorp.com',          '$2b$10$samplehash_techcorp', 'employer'),
('Innovate', 'Solutions','jobs@innovatesol.com',    '$2b$10$samplehash_innovate', 'employer'),
('Global',   'Finance',  'careers@globalfinance.com','$2b$10$samplehash_global',  'employer'),
-- Admin
('Sarah',    'Admin',    'admin@cmich.edu',          '$2b$10$samplehash_admin',    'admin');

-- -------------------------------------------------------
-- Students
-- -------------------------------------------------------
INSERT INTO students (user_id, student_number, major, graduation_year, gpa, phone, bio) VALUES
(1, 'CMU2025001', 'Computer Science',        2025, 3.72, '989-555-0101',
   'Passionate CS student interested in full-stack development and AI.'),
(2, 'CMU2026001', 'Information Systems',     2026, 3.45, '989-555-0102',
   'IS student with strong data analytics skills seeking data-focused roles.'),
(3, 'CMU2025002', 'Business Administration', 2025, 3.60, '989-555-0103',
   'Business student with a focus on project management and process improvement.'),
(4, 'CMU2027001', 'Computer Science',        2027, 3.88, '989-555-0104',
   'Junior CS student looking for internship opportunities in software engineering.');

-- -------------------------------------------------------
-- Advisors
-- -------------------------------------------------------
INSERT INTO advisors (user_id, department, office_location, phone, specialization) VALUES
(5, 'Career Services', 'Warriner Hall 101', '989-774-0201', 'Technology & Engineering'),
(6, 'Career Services', 'Warriner Hall 102', '989-774-0202', 'Business & Management');

-- -------------------------------------------------------
-- Employers
-- -------------------------------------------------------
INSERT INTO employers (user_id, company_name, industry, company_size, website, location, is_verified) VALUES
(7,  'TechCorp Inc.',      'Information Technology', '201-500', 'https://techcorp.com',       'Detroit, MI',       TRUE),
(8,  'Innovate Solutions', 'Software Development',   '51-200',  'https://innovatesol.com',    'Grand Rapids, MI',  TRUE),
(9,  'Global Finance Co.', 'Financial Services',     '501-1000','https://globalfinance.com',  'Midland, MI',       FALSE);

-- -------------------------------------------------------
-- Admins
-- -------------------------------------------------------
INSERT INTO admins (user_id, department) VALUES
(10, 'Career Services');

-- -------------------------------------------------------
-- Skills
-- -------------------------------------------------------
INSERT INTO skills (skill_name, category) VALUES
('Python',            'Programming'),
('Java',              'Programming'),
('JavaScript',        'Programming'),
('SQL',               'Database'),
('React',             'Frontend'),
('Node.js',           'Backend'),
('Data Analysis',     'Analytics'),
('Project Management','Management'),
('Communication',     'Soft Skills'),
('Problem Solving',   'Soft Skills'),
('Microsoft Excel',   'Tools'),
('Tableau',           'Analytics'),
('Git',               'Tools'),
('HTML/CSS',          'Frontend'),
('Machine Learning',  'Analytics');

-- -------------------------------------------------------
-- Student Skills
-- -------------------------------------------------------
INSERT INTO student_skills (student_id, skill_id) VALUES
-- Jordan (CS): Python, Java, JS, SQL, React, Node.js, Git, HTML/CSS
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,13),(1,14),
-- Alex (IS): SQL, Data Analysis, Excel, Tableau, Python
(2,4),(2,7),(2,11),(2,12),(2,1),
-- Maria (Business): Project Mgmt, Communication, Problem Solving, Excel
(3,8),(3,9),(3,10),(3,11),
-- Kevin (CS): Python, Java, ML, SQL, Git
(4,1),(4,2),(4,15),(4,4),(4,13);

-- -------------------------------------------------------
-- Student–Advisor Assignments
-- -------------------------------------------------------
INSERT INTO student_advisor_assignments (student_id, advisor_id, is_active) VALUES
(1, 1, TRUE),   -- Jordan → Lisa Chen (Tech)
(2, 1, TRUE),   -- Alex   → Lisa Chen (Tech)
(3, 2, TRUE),   -- Maria  → Mark Williams (Business)
(4, 1, TRUE);   -- Kevin  → Lisa Chen (Tech)

-- -------------------------------------------------------
-- Job Postings
-- -------------------------------------------------------
INSERT INTO job_postings
  (employer_id, title, description, requirements, location, job_type,
   salary_min, salary_max, application_deadline, status)
VALUES
(1, 'Software Engineering Intern',
   'Join our engineering team to build scalable web applications using Python and React. You will work alongside senior engineers on real features.',
   'Currently pursuing a CS or related degree. Familiarity with Python or JavaScript. Strong problem-solving skills.',
   'Detroit, MI', 'internship', 18.00, 25.00, '2025-05-01', 'active'),

(1, 'Full Stack Developer',
   'Build and maintain customer-facing web applications using React and Node.js. Collaborate with product and design teams.',
   '2+ years of experience with React, Node.js, and SQL. Bachelor\'s degree in Computer Science or related field.',
   'Detroit, MI', 'full-time', 65000.00, 85000.00, '2025-04-15', 'active'),

(2, 'Data Analyst Intern',
   'Analyze business datasets and create dashboards to support decision-making. Work with cross-functional teams.',
   'Statistics, IS, or Math major preferred. Proficient in Excel and SQL. Exposure to Tableau is a plus.',
   'Grand Rapids, MI', 'internship', 17.00, 22.00, '2025-05-15', 'active'),

(2, 'Business Analyst',
   'Gather business requirements, document workflows, and support IT project delivery.',
   'Bachelor\'s in Business or IS. Strong written and verbal communication. Proficiency in Excel.',
   'Remote', 'full-time', 55000.00, 70000.00, '2025-04-30', 'active'),

(3, 'Financial Systems Intern',
   'Support the finance technology team in maintaining and improving internal reporting systems.',
   'Pursuing degree in Finance, Accounting, or IS. Knowledge of Excel and basic SQL.',
   'Midland, MI', 'internship', 16.00, 20.00, '2025-06-01', 'active'),

(1, 'ML Engineer Intern',
   'Work on machine learning pipelines and model deployment for our recommendation system.',
   'CS or Data Science major. Familiarity with Python, pandas, and scikit-learn.',
   'Detroit, MI', 'internship', 20.00, 28.00, '2025-05-10', 'active');

-- -------------------------------------------------------
-- Job Skills (required skills per posting)
-- -------------------------------------------------------
INSERT INTO job_skills (job_id, skill_id) VALUES
-- Job 1: SE Intern → Python, JavaScript, React, Problem Solving
(1,1),(1,3),(1,5),(1,10),
-- Job 2: Full Stack → JavaScript, React, Node.js, SQL, Git
(2,3),(2,5),(2,6),(2,4),(2,13),
-- Job 3: Data Analyst Intern → SQL, Data Analysis, Excel, Tableau
(3,4),(3,7),(3,11),(3,12),
-- Job 4: Business Analyst → Project Mgmt, Communication, Excel
(4,8),(4,9),(4,11),
-- Job 5: Financial Systems Intern → Excel, SQL
(5,11),(5,4),
-- Job 6: ML Intern → Python, Machine Learning, SQL
(6,1),(6,15),(6,4);

-- -------------------------------------------------------
-- Applications
-- -------------------------------------------------------
INSERT INTO applications (student_id, job_id, status, cover_letter) VALUES
(1, 1, 'interview_scheduled',
   'I am excited to apply for the Software Engineering Internship at TechCorp. My experience with Python and React aligns well with this role.'),
(1, 2, 'applied',
   'I am eager to contribute to TechCorps full stack team with my JavaScript and React experience.'),
(1, 6, 'under_review',
   'My Python and machine learning coursework make me a strong candidate for this ML Intern role.'),
(2, 3, 'under_review',
   'My background in data analysis and SQL makes me well-suited for this Data Analyst Intern position.'),
(2, 4, 'applied',
   'I believe my IS background and data skills will bring value to your Business Analyst team.'),
(3, 4, 'applied',
   'As a Business Administration student with strong project management skills, I am confident I can excel in this role.'),
(4, 1, 'applied',
   'I am a motivated CS junior seeking my first internship in software engineering.'),
(4, 6, 'interview_scheduled',
   'Machine learning is my academic focus and I would love to apply it at TechCorp.');

-- -------------------------------------------------------
-- Interviews
-- -------------------------------------------------------
INSERT INTO interviews
  (application_id, scheduled_date, scheduled_time, interview_type,
   location_or_link, duration_minutes, status, prep_notes)
VALUES
(1, '2025-03-20', '14:00:00', 'video',
   'https://teams.microsoft.com/meeting/abc123',
   45, 'scheduled',
   'Review Python basics and STAR behavioral responses. Research TechCorp products.'),
(8, '2025-03-22', '10:00:00', 'technical',
   'https://teams.microsoft.com/meeting/xyz456',
   60, 'scheduled',
   'Prepare for Python coding challenge. Review pandas and scikit-learn APIs.');

-- -------------------------------------------------------
-- Advising Notes
-- -------------------------------------------------------
INSERT INTO advising_notes (advisor_id, student_id, note_content, note_type, is_private) VALUES
(1, 1, 'Jordan has strong technical skills. Recommended updating LinkedIn profile before applying to TechCorp.',
   'general', FALSE),
(1, 1, 'Reviewed Jordan''s resume — suggested adding quantifiable achievements (e.g., "reduced load time by 30%").',
   'resume_review', FALSE),
(1, 1, 'Jordan has an interview with TechCorp on March 20. Advised to practice behavioral questions using STAR method.',
   'interview_prep', FALSE),
(1, 2, 'Alex should focus on strengthening SQL and Tableau skills. Suggested completing the Tableau Public course.',
   'career_goal', FALSE),
(1, 2, 'Alex applied to Data Analyst Intern at Innovate Solutions. Application looks strong — under review.',
   'application_advice', FALSE),
(2, 3, 'Maria is an excellent communicator. Encouraged her to apply for the Business Analyst role at Innovate Solutions.',
   'application_advice', FALSE),
(2, 3, 'Shared a list of upcoming career fair employers in the business/finance sector.',
   'general', FALSE),
(1, 4, 'Kevin is one of our top performers. His ML focus is well-aligned with the TechCorp ML Intern posting.',
   'general', FALSE);

-- ==============================================================
--  VIEWS  (support DFD processes & UI dashboards)
-- ==============================================================

-- -------------------------------------------------------
-- View: Student application tracker (student-applications.html)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_student_applications AS
SELECT
    a.application_id,
    CONCAT(su.first_name, ' ', su.last_name) AS student_name,
    su.email                                  AS student_email,
    s.major,
    s.graduation_year,
    jp.title                                  AS job_title,
    em.company_name,
    jp.job_type,
    jp.location,
    a.status                                  AS application_status,
    a.applied_at,
    a.updated_at
FROM applications a
JOIN students    s   ON a.student_id   = s.student_id
JOIN users       su  ON s.user_id      = su.user_id
JOIN job_postings jp ON a.job_id       = jp.job_id
JOIN employers   em  ON jp.employer_id = em.employer_id;

-- -------------------------------------------------------
-- View: Upcoming interviews (student-interviews.html)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_upcoming_interviews AS
SELECT
    i.interview_id,
    CONCAT(su.first_name, ' ', su.last_name) AS student_name,
    jp.title                                  AS job_title,
    em.company_name,
    i.scheduled_date,
    i.scheduled_time,
    i.interview_type,
    i.location_or_link,
    i.duration_minutes,
    i.status,
    i.prep_notes
FROM interviews  i
JOIN applications a  ON i.application_id = a.application_id
JOIN students    s   ON a.student_id     = s.student_id
JOIN users       su  ON s.user_id        = su.user_id
JOIN job_postings jp ON a.job_id         = jp.job_id
JOIN employers   em  ON jp.employer_id   = em.employer_id
WHERE i.status IN ('scheduled','rescheduled')
ORDER BY i.scheduled_date, i.scheduled_time;

-- -------------------------------------------------------
-- View: Advisor student overview (advisor-students.html)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_advisor_students AS
SELECT
    CONCAT(au.first_name, ' ', au.last_name) AS advisor_name,
    saa.advisor_id,
    saa.student_id,
    CONCAT(su.first_name, ' ', su.last_name) AS student_name,
    su.email                                  AS student_email,
    s.major,
    s.graduation_year,
    s.gpa,
    COUNT(DISTINCT a.application_id)          AS total_applications,
    COUNT(DISTINCT i.interview_id)            AS total_interviews,
    SUM(a.status = 'offer_extended')          AS offers_received,
    SUM(a.status = 'accepted')                AS offers_accepted
FROM student_advisor_assignments saa
JOIN advisors    adv ON saa.advisor_id = adv.advisor_id
JOIN users       au  ON adv.user_id    = au.user_id
JOIN students    s   ON saa.student_id = s.student_id
JOIN users       su  ON s.user_id      = su.user_id
LEFT JOIN applications  a ON s.student_id      = a.student_id
LEFT JOIN interviews    i ON a.application_id  = i.interview_id
WHERE saa.is_active = TRUE
GROUP BY saa.advisor_id, saa.student_id,
         au.first_name, au.last_name,
         su.first_name, su.last_name, su.email,
         s.major, s.graduation_year, s.gpa;

-- -------------------------------------------------------
-- View: Employer applicant list (employer-applicants.html)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_employer_applicants AS
SELECT
    em.employer_id,
    em.company_name,
    jp.job_id,
    jp.title                                  AS job_title,
    jp.job_type,
    a.application_id,
    CONCAT(su.first_name, ' ', su.last_name) AS applicant_name,
    su.email                                  AS applicant_email,
    s.major,
    s.graduation_year,
    s.gpa,
    a.status                                  AS application_status,
    a.applied_at
FROM applications a
JOIN students    s   ON a.student_id   = s.student_id
JOIN users       su  ON s.user_id      = su.user_id
JOIN job_postings jp ON a.job_id       = jp.job_id
JOIN employers   em  ON jp.employer_id = em.employer_id;

-- -------------------------------------------------------
-- View: Admin reports – application stats (admin-reports.html)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_admin_application_stats AS
SELECT
    em.company_name,
    jp.title                                      AS job_title,
    jp.job_type,
    jp.status                                     AS job_status,
    COUNT(a.application_id)                       AS total_applications,
    SUM(a.status = 'applied')                     AS cnt_applied,
    SUM(a.status = 'under_review')                AS cnt_under_review,
    SUM(a.status = 'interview_scheduled')         AS cnt_interview,
    SUM(a.status = 'offer_extended')              AS cnt_offer,
    SUM(a.status = 'accepted')                    AS cnt_accepted,
    SUM(a.status = 'rejected')                    AS cnt_rejected
FROM job_postings jp
JOIN employers   em ON jp.employer_id = em.employer_id
LEFT JOIN applications a ON jp.job_id = a.job_id
GROUP BY jp.job_id, em.company_name, jp.title, jp.job_type, jp.status;

-- ==============================================================
--  USEFUL QUERIES  (reference for backend developers)
-- ==============================================================

-- Q1: Find all active jobs that match a student's skills
-- SELECT DISTINCT jp.*
-- FROM job_postings jp
-- JOIN job_skills js ON jp.job_id = js.job_id
-- JOIN student_skills ss ON js.skill_id = ss.skill_id
-- WHERE ss.student_id = 1 AND jp.status = 'active';

-- Q2: Get a student's full application timeline
-- SELECT a.application_id, jp.title, em.company_name,
--        a.status, a.applied_at,
--        i.scheduled_date, i.interview_type, i.status AS interview_status
-- FROM applications a
-- JOIN job_postings jp ON a.job_id = jp.job_id
-- JOIN employers em ON jp.employer_id = em.employer_id
-- LEFT JOIN interviews i ON a.application_id = i.application_id
-- WHERE a.student_id = 1
-- ORDER BY a.applied_at DESC;

-- Q3: Advisor's notes for a specific student
-- SELECT n.created_at, n.note_type, n.note_content,
--        CONCAT(au.first_name,' ',au.last_name) AS advisor
-- FROM advising_notes n
-- JOIN advisors adv ON n.advisor_id = adv.advisor_id
-- JOIN users au ON adv.user_id = au.user_id
-- WHERE n.student_id = 1
-- ORDER BY n.created_at DESC;

-- Q4: Placement rate by major (admin-reports.html)
-- SELECT s.major,
--        COUNT(DISTINCT s.student_id)                        AS total_students,
--        COUNT(DISTINCT CASE WHEN a.status='accepted'
--              THEN a.student_id END)                        AS placed_students,
--        ROUND(COUNT(DISTINCT CASE WHEN a.status='accepted'
--              THEN a.student_id END)
--              / COUNT(DISTINCT s.student_id) * 100, 1)      AS placement_rate_pct
-- FROM students s
-- LEFT JOIN applications a ON s.student_id = a.student_id
-- GROUP BY s.major;

-- ==============================================================
--  VERIFY (quick row counts)
-- ==============================================================
SELECT 'users'           AS tbl, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'students',                COUNT(*)             FROM students
UNION ALL
SELECT 'advisors',                COUNT(*)             FROM advisors
UNION ALL
SELECT 'employers',               COUNT(*)             FROM employers
UNION ALL
SELECT 'admins',                  COUNT(*)             FROM admins
UNION ALL
SELECT 'skills',                  COUNT(*)             FROM skills
UNION ALL
SELECT 'job_postings',            COUNT(*)             FROM job_postings
UNION ALL
SELECT 'applications',            COUNT(*)             FROM applications
UNION ALL
SELECT 'interviews',              COUNT(*)             FROM interviews
UNION ALL
SELECT 'advising_notes',          COUNT(*)             FROM advising_notes;
