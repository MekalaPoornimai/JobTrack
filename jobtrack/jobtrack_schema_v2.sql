-- ==============================================================
--  JobTrack – Job/Internship Application Tracking System
--  Central Michigan University (CMU)
--  DATABASE SCHEMA  v2.0  (Streamlit + MySQL Edition)
--
--  Updated from v1:
--    • Added profile_complete_pct to students table
--    • Added resume_url / linkedin_url sample values
--    • All application dates updated to March 2025 (matches UI)
--    • Application statuses corrected to match Streamlit UI metrics
--      Admin total: 3 applied | 2 under_review | 2 interview | 1 rejected
--    • Interview dates updated to Mar 20 & Mar 22, 2025
--    • 5 original views retained + 5 new Streamlit-specific views
--
--  Entities:  User · Student · Advisor · Employer · Admin
--             Job_Posting · Application · Interview · AdvisingNote · Skill
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
-- -------------------------------------------------------
CREATE TABLE users (
    user_id       INT          AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,   -- CMU or company email
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
    student_id           INT            AUTO_INCREMENT PRIMARY KEY,
    user_id              INT            NOT NULL UNIQUE,
    student_number       VARCHAR(20)    UNIQUE,
    major                VARCHAR(100),
    graduation_year      YEAR,
    gpa                  DECIMAL(3,2)   CHECK (gpa BETWEEN 0.00 AND 4.00),
    phone                VARCHAR(20),
    bio                  TEXT,
    resume_url           VARCHAR(500),
    linkedin_url         VARCHAR(500),
    portfolio_url        VARCHAR(500),
    profile_complete_pct TINYINT UNSIGNED DEFAULT 0,   -- 0–100 cached completion %
    profile_complete     BOOLEAN        DEFAULT FALSE,
    created_at           DATETIME       DEFAULT CURRENT_TIMESTAMP,
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
    specialization  VARCHAR(200),
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
-- TABLE: admins
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
-- TABLE: skills
-- -------------------------------------------------------
CREATE TABLE skills (
    skill_id   INT          AUTO_INCREMENT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category   VARCHAR(50)
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
--  JOB POSTINGS
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
--  APPLICATIONS
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
    student_notes  TEXT,
    applied_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)    ON DELETE CASCADE,
    FOREIGN KEY (job_id)     REFERENCES job_postings(job_id)    ON DELETE CASCADE,
    UNIQUE KEY uq_student_job (student_id, job_id),
    INDEX idx_status     (status),
    INDEX idx_applied_at (applied_at)
);

-- ==============================================================
--  INTERVIEWS
-- ==============================================================
CREATE TABLE interviews (
    interview_id     INT          AUTO_INCREMENT PRIMARY KEY,
    application_id   INT          NOT NULL,
    scheduled_date   DATE         NOT NULL,
    scheduled_time   TIME         NOT NULL,
    interview_type   ENUM('phone','video','in-person','technical','panel') NOT NULL,
    location_or_link VARCHAR(500),
    duration_minutes INT          DEFAULT 60,
    status           ENUM('scheduled','completed','cancelled','rescheduled','no_show')
                                  DEFAULT 'scheduled',
    prep_notes       TEXT,
    feedback_notes   TEXT,
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE,
    INDEX idx_scheduled_date (scheduled_date),
    INDEX idx_status         (status)
);

-- ==============================================================
--  ADVISING NOTES
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
    is_private   BOOLEAN  DEFAULT FALSE,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (advisor_id) REFERENCES advisors(advisor_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    INDEX idx_advisor   (advisor_id),
    INDEX idx_student   (student_id),
    INDEX idx_note_type (note_type)
);

-- ==============================================================
--  SAMPLE DATA
-- ==============================================================

-- -------------------------------------------------------
-- Users  (password = bcrypt of 'Test@1234' – change in prod)
-- -------------------------------------------------------
INSERT INTO users (first_name, last_name, email, password_hash, role) VALUES
-- Students (user_id 1–4)
('Jordan',   'Smith',    'smith1js@cmich.edu',       '$2b$10$samplehash_jordan',    'student'),
('Alex',     'Johnson',  'johnson2aj@cmich.edu',     '$2b$10$samplehash_alex',      'student'),
('Maria',    'Garcia',   'garcia3mg@cmich.edu',      '$2b$10$samplehash_maria',     'student'),
('Kevin',    'Patel',    'patel4kp@cmich.edu',       '$2b$10$samplehash_kevin',     'student'),
-- Advisors (user_id 5–6)
('Lisa',     'Chen',     'chen5lc@cmich.edu',        '$2b$10$samplehash_lisa',      'advisor'),
('Mark',     'Williams', 'williams6mw@cmich.edu',    '$2b$10$samplehash_mark',      'advisor'),
-- Employers (user_id 7–9)
('Tech',     'Corp',     'hr@techcorp.com',           '$2b$10$samplehash_techcorp',  'employer'),
('Innovate', 'Solutions','jobs@innovatesol.com',     '$2b$10$samplehash_innovate',  'employer'),
('Global',   'Finance',  'careers@globalfinance.com','$2b$10$samplehash_global',    'employer'),
-- Admin (user_id 10)
('Sarah',    'Admin',    'admin@cmich.edu',           '$2b$10$samplehash_admin',     'admin');

-- -------------------------------------------------------
-- Students  (profile_complete_pct matches Streamlit UI)
-- -------------------------------------------------------
-- Jordan: resume + LinkedIn present, portfolio missing → 82%
-- Alex:   resume present, LinkedIn/portfolio missing  → 70%
-- Maria:  no URLs added yet                           → 65%
-- Kevin:  resume + LinkedIn present, portfolio missing→ 78%
INSERT INTO students
  (user_id, student_number, major, graduation_year, gpa, phone, bio,
   resume_url, linkedin_url, portfolio_url, profile_complete_pct)
VALUES
(1, 'CMU2025001', 'Computer Science',        2025, 3.72, '989-555-0101',
 'Passionate CS student interested in full-stack development and AI.',
 'https://drive.google.com/file/d/jordan-smith-resume',
 'https://linkedin.com/in/jordan-smith-cmu',
 NULL, 82),

(2, 'CMU2026001', 'Information Systems',     2026, 3.45, '989-555-0102',
 'IS student with strong data analytics skills seeking data-focused roles.',
 'https://drive.google.com/file/d/alex-johnson-resume',
 NULL, NULL, 70),

(3, 'CMU2025002', 'Business Administration', 2025, 3.60, '989-555-0103',
 'Business student with a focus on project management and process improvement.',
 NULL, NULL, NULL, 65),

(4, 'CMU2027001', 'Computer Science',        2027, 3.88, '989-555-0104',
 'Junior CS student looking for internship opportunities in software engineering.',
 'https://drive.google.com/file/d/kevin-patel-resume',
 'https://linkedin.com/in/kevin-patel-cmu',
 NULL, 78);

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
(7, 'TechCorp Inc.',      'Information Technology', '201-500',  'https://techcorp.com',       'Detroit, MI',      TRUE),
(8, 'Innovate Solutions', 'Software Development',   '51-200',   'https://innovatesol.com',    'Grand Rapids, MI', TRUE),
(9, 'Global Finance Co.', 'Financial Services',     '501-1000', 'https://globalfinance.com',  'Midland, MI',      FALSE);
-- NOTE: Global Finance Co. is_verified=FALSE → shows as pending on Admin Dashboard

-- -------------------------------------------------------
-- Admins
-- -------------------------------------------------------
INSERT INTO admins (user_id, department) VALUES (10, 'Career Services');

-- -------------------------------------------------------
-- Skills (15 skills matching UI chips)
-- -------------------------------------------------------
INSERT INTO skills (skill_name, category) VALUES
('Python',            'Programming'),   -- skill_id 1
('Java',              'Programming'),   -- 2
('JavaScript',        'Programming'),   -- 3
('SQL',               'Database'),      -- 4
('React',             'Frontend'),      -- 5
('Node.js',           'Backend'),       -- 6
('Data Analysis',     'Analytics'),     -- 7
('Project Management','Management'),    -- 8
('Communication',     'Soft Skills'),   -- 9
('Problem Solving',   'Soft Skills'),   -- 10
('Microsoft Excel',   'Tools'),         -- 11
('Tableau',           'Analytics'),     -- 12
('Git',               'Tools'),         -- 13
('HTML/CSS',          'Frontend'),      -- 14
('Machine Learning',  'Analytics');     -- 15

-- -------------------------------------------------------
-- Student Skills
-- -------------------------------------------------------
INSERT INTO student_skills (student_id, skill_id) VALUES
-- Jordan (CS): Python, Java, JS, SQL, React, Node.js, Git, HTML/CSS
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,13),(1,14),
-- Alex (IS): Python, SQL, Data Analysis, Excel, Tableau
(2,1),(2,4),(2,7),(2,11),(2,12),
-- Maria (Business): Project Mgmt, Communication, Problem Solving, Excel
(3,8),(3,9),(3,10),(3,11),
-- Kevin (CS): Python, Java, SQL, Git, Machine Learning
(4,1),(4,2),(4,4),(4,13),(4,15);

-- -------------------------------------------------------
-- Student–Advisor Assignments
-- -------------------------------------------------------
INSERT INTO student_advisor_assignments (student_id, advisor_id, is_active) VALUES
(1, 1, TRUE),   -- Jordan → Dr. Lisa Chen   (Technology)
(2, 1, TRUE),   -- Alex   → Dr. Lisa Chen
(3, 2, TRUE),   -- Maria  → Mark Williams   (Business)
(4, 1, TRUE);   -- Kevin  → Dr. Lisa Chen

-- -------------------------------------------------------
-- Job Postings  (6 active – matches "6 Active Jobs" metric)
-- -------------------------------------------------------
INSERT INTO job_postings
  (employer_id, title, description, requirements, location, job_type,
   salary_min, salary_max, application_deadline, status, posted_at)
VALUES
-- TechCorp (employer_id 1) – 3 jobs
(1, 'Software Engineering Intern',
   'Join our engineering team to build scalable web applications using Python and React. Work alongside senior engineers on real product features.',
   'Currently pursuing CS or related degree. Familiarity with Python or JavaScript. Strong problem-solving skills.',
   'Detroit, MI', 'internship', 18.00, 25.00, '2025-05-01', 'active', '2025-03-01 08:00:00'),

(1, 'Full Stack Developer',
   'Build and maintain customer-facing web applications with React and Node.js. Collaborate with product and design teams.',
   '2+ years React, Node.js, and SQL experience. Bachelor\'s degree in CS or related field.',
   'Detroit, MI', 'full-time', 65000.00, 85000.00, '2025-04-15', 'active', '2025-03-02 09:00:00'),

(1, 'ML Engineer Intern',
   'Work on machine learning pipelines and model deployment for our recommendation system.',
   'CS or Data Science major. Familiarity with Python, pandas, and scikit-learn.',
   'Detroit, MI', 'internship', 20.00, 28.00, '2025-05-10', 'active', '2025-03-05 10:00:00'),

-- Innovate Solutions (employer_id 2) – 2 jobs
(2, 'Data Analyst Intern',
   'Analyze business datasets and create dashboards to support decision-making. Work with cross-functional teams.',
   'Statistics, IS, or Math major preferred. Proficient in Excel and SQL. Exposure to Tableau is a plus.',
   'Grand Rapids, MI', 'internship', 17.00, 22.00, '2025-05-15', 'active', '2025-03-03 08:30:00'),

(2, 'Business Analyst',
   'Gather requirements, document workflows, and support IT project delivery across business units.',
   'Bachelor\'s in Business or IS. Strong written and verbal communication. Proficiency in Excel.',
   'Remote', 'full-time', 55000.00, 70000.00, '2025-04-30', 'active', '2025-03-04 11:00:00'),

-- Global Finance Co. (employer_id 3) – 1 job
(3, 'Financial Systems Intern',
   'Support the finance technology team in maintaining and improving internal reporting systems.',
   'Pursuing degree in Finance, Accounting, or IS. Knowledge of Excel and basic SQL.',
   'Midland, MI', 'internship', 16.00, 20.00, '2025-06-01', 'active', '2025-03-06 09:00:00');

-- -------------------------------------------------------
-- Job Skills  (required skills per posting)
-- -------------------------------------------------------
INSERT INTO job_skills (job_id, skill_id) VALUES
-- Job 1 (SE Intern):       Python, JavaScript, React, Problem Solving
(1,1),(1,3),(1,5),(1,10),
-- Job 2 (Full Stack Dev):  JavaScript, React, Node.js, SQL, Git
(2,3),(2,5),(2,6),(2,4),(2,13),
-- Job 3 (Data Analyst):    SQL, Data Analysis, Excel, Tableau
(3,4),(3,7),(3,11),(3,12),
-- Job 4 (Business Analyst):Project Management, Communication, Excel
(4,8),(4,9),(4,11),
-- Job 5 (Financial Intern):Excel, SQL
(5,11),(5,4),
-- Job 6 (ML Intern):       Python, Machine Learning, SQL
(6,1),(6,15),(6,4);

-- -------------------------------------------------------
-- Applications  (8 total – matches all UI dashboards)
--
-- Status breakdown (matches Admin Reports bar chart exactly):
--   applied:              Jordan→job2 | Alex→job4 | Kevin→job1  = 3
--   under_review:         Jordan→job6 | Alex→job3               = 2
--   interview_scheduled:  Jordan→job1 | Kevin→job6              = 2
--   rejected:             Maria→job4                             = 1
--   Total = 8
--
-- TechCorp breakdown (job1, job2, job6):
--   Total: 5 | Under review: 1 | Interview: 2 | Applied: 2
-- -------------------------------------------------------
INSERT INTO applications
  (student_id, job_id, status, cover_letter, applied_at)
VALUES
-- application_id 1
(1, 1, 'interview_scheduled',
 'I am excited to apply for the Software Engineering Internship at TechCorp. My Python and React experience aligns well with this role.',
 '2025-03-10 09:00:00'),

-- application_id 2
(1, 2, 'applied',
 'I am eager to contribute to TechCorp\'s full stack team with my JavaScript and React experience.',
 '2025-03-12 11:30:00'),

-- application_id 3
(1, 6, 'under_review',
 'My Python and machine learning coursework make me a strong candidate for this ML Intern role.',
 '2025-03-14 14:00:00'),

-- application_id 4
(2, 3, 'under_review',
 'My background in data analysis and SQL makes me well-suited for this Data Analyst Intern position.',
 '2025-03-11 10:00:00'),

-- application_id 5
(2, 4, 'applied',
 'My IS background and data skills will bring strong value to the Business Analyst team.',
 '2025-03-13 15:30:00'),

-- application_id 6  ← rejected (matches admin reports "1 Rejected")
(3, 4, 'rejected',
 'As a Business Administration student with strong project management skills, I am confident in this role.',
 '2025-03-08 09:00:00'),

-- application_id 7
(4, 1, 'applied',
 'I am a motivated CS junior seeking my first internship in software engineering.',
 '2025-03-14 16:00:00'),

-- application_id 8
(4, 6, 'interview_scheduled',
 'Machine learning is my academic focus and I would love to apply it at TechCorp.',
 '2025-03-15 10:00:00');

-- -------------------------------------------------------
-- Interviews  (2 scheduled – matches "2 Interviews" metric)
-- -------------------------------------------------------
INSERT INTO interviews
  (application_id, scheduled_date, scheduled_time, interview_type,
   location_or_link, duration_minutes, status, prep_notes)
VALUES
-- Interview 1: Jordan Smith → SE Intern @ TechCorp  (Mar 20 14:00 Video)
(1, '2025-03-20', '14:00:00', 'video',
 'https://teams.microsoft.com/meeting/techcorp-jordan-abc123',
 45, 'scheduled',
 'Review Python basics and STAR behavioral responses. Research TechCorp products and recent news.'),

-- Interview 2: Kevin Patel → ML Intern @ TechCorp  (Mar 22 10:00 Technical)
(8, '2025-03-22', '10:00:00', 'technical',
 'https://teams.microsoft.com/meeting/techcorp-kevin-xyz456',
 60, 'scheduled',
 'Prepare for Python coding challenge. Review pandas, scikit-learn APIs, and ML pipeline concepts.');

-- -------------------------------------------------------
-- Advising Notes  (8 total – matches "8 Notes" metric)
-- -------------------------------------------------------
INSERT INTO advising_notes
  (advisor_id, student_id, note_content, note_type, is_private, created_at)
VALUES
-- Lisa Chen's notes on Jordan (3 notes)
(1, 1,
 'Jordan has strong technical skills. Recommended updating LinkedIn profile and adding portfolio link before applying to TechCorp.',
 'general', FALSE, '2025-03-07 10:00:00'),

(1, 1,
 'Reviewed Jordan''s resume — suggested adding quantifiable achievements such as "reduced load time by 30%". Resume is strong overall.',
 'resume_review', FALSE, '2025-03-10 11:00:00'),

(1, 1,
 'Jordan has an interview with TechCorp on March 20. Advised to practice STAR method behavioral responses and research company products.',
 'interview_prep', FALSE, '2025-03-14 09:00:00'),

-- Lisa Chen's notes on Alex (2 notes)
(1, 2,
 'Alex should focus on strengthening SQL and Tableau skills. Suggested completing the free Tableau Public course.',
 'career_goal', FALSE, '2025-03-08 14:00:00'),

(1, 2,
 'Alex applied to Data Analyst Intern at Innovate Solutions. Application under review — strong match for the role.',
 'application_advice', FALSE, '2025-03-11 15:00:00'),

-- Mark Williams' notes on Maria (2 notes)
(2, 3,
 'Maria is an excellent communicator. Encouraged her to apply for the Business Analyst role at Innovate Solutions despite the rejection from prior posting.',
 'application_advice', FALSE, '2025-03-09 10:00:00'),

(2, 3,
 'Shared a list of upcoming CMU career fair employers in the business and finance sector. Maria should attend.',
 'general', FALSE, '2025-03-12 11:00:00'),

-- Lisa Chen's note on Kevin (1 note)
(1, 4,
 'Kevin is one of our top performers this semester. His ML and Python focus is well-aligned with the TechCorp ML Intern posting. Interview confirmed for Mar 22.',
 'general', FALSE, '2025-03-15 09:00:00');

-- ==============================================================
--  VIEWS  (original 5 + 5 new Streamlit-specific)
-- ==============================================================

-- -------------------------------------------------------
-- VIEW 1: vw_student_applications  (student-applications page)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_student_applications AS
SELECT
    a.application_id,
    a.student_id,
    CONCAT(su.first_name, ' ', su.last_name)  AS student_name,
    su.email                                   AS student_email,
    s.major,
    s.graduation_year,
    a.job_id,
    jp.title                                   AS job_title,
    em.employer_id,
    em.company_name,
    jp.job_type,
    jp.location,
    jp.salary_min,
    jp.salary_max,
    a.status                                   AS application_status,
    a.applied_at,
    a.updated_at
FROM applications a
JOIN students    s   ON a.student_id   = s.student_id
JOIN users       su  ON s.user_id      = su.user_id
JOIN job_postings jp ON a.job_id       = jp.job_id
JOIN employers   em  ON jp.employer_id = em.employer_id;

-- -------------------------------------------------------
-- VIEW 2: vw_upcoming_interviews  (student-interviews page)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_upcoming_interviews AS
SELECT
    i.interview_id,
    i.application_id,
    a.student_id,
    CONCAT(su.first_name, ' ', su.last_name)  AS student_name,
    su.email                                   AS student_email,
    jp.job_id,
    jp.title                                   AS job_title,
    em.company_name,
    i.scheduled_date,
    i.scheduled_time,
    i.interview_type,
    i.location_or_link,
    i.duration_minutes,
    i.status,
    i.prep_notes,
    i.feedback_notes
FROM interviews  i
JOIN applications a  ON i.application_id = a.application_id
JOIN students    s   ON a.student_id     = s.student_id
JOIN users       su  ON s.user_id        = su.user_id
JOIN job_postings jp ON a.job_id         = jp.job_id
JOIN employers   em  ON jp.employer_id   = em.employer_id
WHERE i.status IN ('scheduled','rescheduled')
ORDER BY i.scheduled_date, i.scheduled_time;

-- -------------------------------------------------------
-- VIEW 3: vw_advisor_students  (advisor-students page)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_advisor_students AS
SELECT
    saa.advisor_id,
    CONCAT(au.first_name, ' ', au.last_name)  AS advisor_name,
    saa.student_id,
    CONCAT(su.first_name, ' ', su.last_name)  AS student_name,
    su.email                                   AS student_email,
    s.major,
    s.graduation_year,
    s.gpa,
    s.profile_complete_pct,
    s.resume_url,
    s.linkedin_url,
    COUNT(DISTINCT a.application_id)           AS total_applications,
    COUNT(DISTINCT CASE WHEN a.status='interview_scheduled'
                   THEN a.application_id END)  AS interviews_count,
    COUNT(DISTINCT CASE WHEN a.status='offer_extended'
                   THEN a.application_id END)  AS offers_count,
    COUNT(DISTINCT CASE WHEN a.status='accepted'
                   THEN a.application_id END)  AS placements_count
FROM student_advisor_assignments saa
JOIN advisors    adv ON saa.advisor_id = adv.advisor_id
JOIN users       au  ON adv.user_id    = au.user_id
JOIN students    s   ON saa.student_id = s.student_id
JOIN users       su  ON s.user_id      = su.user_id
LEFT JOIN applications a ON s.student_id = a.student_id
WHERE saa.is_active = TRUE
GROUP BY saa.advisor_id, saa.student_id,
         au.first_name, au.last_name,
         su.first_name, su.last_name, su.email,
         s.major, s.graduation_year, s.gpa,
         s.profile_complete_pct, s.resume_url, s.linkedin_url;

-- -------------------------------------------------------
-- VIEW 4: vw_employer_applicants  (employer-applicants page)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_employer_applicants AS
SELECT
    em.employer_id,
    em.company_name,
    jp.job_id,
    jp.title                                   AS job_title,
    jp.job_type,
    a.application_id,
    a.student_id,
    CONCAT(su.first_name, ' ', su.last_name)  AS applicant_name,
    su.email                                   AS applicant_email,
    s.major,
    s.graduation_year,
    s.gpa,
    s.resume_url,
    s.linkedin_url,
    a.status                                   AS application_status,
    a.applied_at,
    a.cover_letter
FROM applications a
JOIN students    s   ON a.student_id   = s.student_id
JOIN users       su  ON s.user_id      = su.user_id
JOIN job_postings jp ON a.job_id       = jp.job_id
JOIN employers   em  ON jp.employer_id = em.employer_id;

-- -------------------------------------------------------
-- VIEW 5: vw_admin_application_stats  (admin-reports page)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_admin_application_stats AS
SELECT
    em.company_name,
    jp.job_id,
    jp.title                                   AS job_title,
    jp.job_type,
    jp.status                                  AS job_status,
    COUNT(a.application_id)                    AS total_applications,
    SUM(a.status = 'applied')                  AS cnt_applied,
    SUM(a.status = 'under_review')             AS cnt_under_review,
    SUM(a.status = 'interview_scheduled')      AS cnt_interview,
    SUM(a.status = 'offer_extended')           AS cnt_offer,
    SUM(a.status = 'accepted')                 AS cnt_accepted,
    SUM(a.status = 'rejected')                 AS cnt_rejected
FROM job_postings jp
JOIN employers   em ON jp.employer_id = em.employer_id
LEFT JOIN applications a ON jp.job_id = a.job_id
GROUP BY jp.job_id, em.company_name, jp.title, jp.job_type, jp.status;

-- -------------------------------------------------------
-- VIEW 6: vw_student_dashboard_metrics  (student dashboard)
-- Returns a single row of metrics for one student
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_student_dashboard_metrics AS
SELECT
    s.student_id,
    CONCAT(u.first_name, ' ', u.last_name)     AS student_name,
    u.email,
    s.major,
    s.graduation_year,
    s.gpa,
    s.profile_complete_pct,
    COUNT(DISTINCT a.application_id)            AS total_applications,
    SUM(a.status = 'applied')                   AS cnt_applied,
    SUM(a.status = 'under_review')              AS cnt_under_review,
    SUM(a.status = 'interview_scheduled')       AS cnt_interview,
    SUM(a.status = 'offer_extended')            AS cnt_offer,
    SUM(a.status = 'accepted')                  AS cnt_accepted,
    SUM(a.status = 'rejected')                  AS cnt_rejected,
    (SELECT COUNT(*) FROM job_postings
     WHERE status = 'active')                   AS active_job_count,
    (SELECT COUNT(*) FROM interviews i2
     JOIN applications a2 ON i2.application_id = a2.application_id
     WHERE a2.student_id = s.student_id
       AND i2.status = 'scheduled')             AS scheduled_interviews
FROM students s
JOIN users u ON s.user_id = u.user_id
LEFT JOIN applications a ON s.student_id = a.student_id
GROUP BY s.student_id, u.first_name, u.last_name, u.email,
         s.major, s.graduation_year, s.gpa, s.profile_complete_pct;

-- -------------------------------------------------------
-- VIEW 7: vw_advisor_dashboard_metrics  (advisor dashboard)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_advisor_dashboard_metrics AS
SELECT
    adv.advisor_id,
    CONCAT(u.first_name, ' ', u.last_name)     AS advisor_name,
    adv.specialization,
    adv.office_location,
    COUNT(DISTINCT saa.student_id)             AS total_students,
    COUNT(DISTINCT a.application_id)           AS total_applications,
    (SELECT COUNT(*)
     FROM interviews i2
     JOIN applications a2  ON i2.application_id = a2.application_id
     JOIN students    s2   ON a2.student_id      = s2.student_id
     JOIN student_advisor_assignments saa2
                           ON s2.student_id      = saa2.student_id
     WHERE saa2.advisor_id = adv.advisor_id
       AND i2.status       = 'scheduled'
       AND i2.scheduled_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    )                                          AS interviews_this_week,
    COUNT(DISTINCT n.note_id)                  AS total_notes
FROM advisors  adv
JOIN users     u    ON adv.user_id   = u.user_id
JOIN student_advisor_assignments saa ON adv.advisor_id = saa.advisor_id AND saa.is_active = TRUE
JOIN students  s    ON saa.student_id = s.student_id
LEFT JOIN applications  a ON s.student_id  = a.student_id
LEFT JOIN advising_notes n ON adv.advisor_id = n.advisor_id
GROUP BY adv.advisor_id, u.first_name, u.last_name,
         adv.specialization, adv.office_location;

-- -------------------------------------------------------
-- VIEW 8: vw_employer_dashboard_metrics  (employer dashboard)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_employer_dashboard_metrics AS
SELECT
    em.employer_id,
    em.company_name,
    em.industry,
    em.location,
    em.is_verified,
    COUNT(DISTINCT CASE WHEN jp.status = 'active' THEN jp.job_id END)             AS active_jobs,
    COUNT(DISTINCT a.application_id)                                               AS total_applicants,
    COUNT(DISTINCT CASE WHEN a.status = 'interview_scheduled'
                   THEN a.application_id END)                                      AS interview_count,
    COUNT(DISTINCT CASE WHEN a.status IN ('accepted','offer_extended')
                   THEN a.application_id END)                                      AS positions_filled,
    ROUND(AVG(s.gpa), 2)                                                           AS avg_applicant_gpa,
    (SELECT COUNT(*)
     FROM interviews i2
     JOIN applications a2  ON i2.application_id = a2.application_id
     JOIN job_postings jp2 ON a2.job_id = jp2.job_id
     WHERE jp2.employer_id = em.employer_id
       AND i2.status = 'scheduled')                                                AS upcoming_interviews
FROM employers em
LEFT JOIN job_postings jp ON em.employer_id   = jp.employer_id
LEFT JOIN applications  a ON jp.job_id         = a.job_id
LEFT JOIN students      s ON a.student_id      = s.student_id
GROUP BY em.employer_id, em.company_name, em.industry,
         em.location, em.is_verified;

-- -------------------------------------------------------
-- VIEW 9: vw_admin_summary  (admin dashboard system-wide stats)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_admin_summary AS
SELECT
    (SELECT COUNT(*) FROM users    WHERE role='student'  AND is_active=TRUE) AS total_students,
    (SELECT COUNT(*) FROM users    WHERE role='advisor'  AND is_active=TRUE) AS total_advisors,
    (SELECT COUNT(*) FROM users    WHERE role='employer' AND is_active=TRUE) AS total_employers,
    (SELECT COUNT(*) FROM job_postings WHERE status='active')                AS active_jobs,
    (SELECT COUNT(*) FROM applications)                                      AS total_applications,
    (SELECT COUNT(*) FROM interviews WHERE status='scheduled')               AS scheduled_interviews,
    (SELECT COUNT(*) FROM applications WHERE status='accepted')              AS placements,
    (SELECT COUNT(*) FROM advising_notes)                                    AS total_notes,
    (SELECT COUNT(*) FROM employers WHERE is_verified=FALSE)                 AS pending_verifications,
    ROUND(
      (SELECT COUNT(*) FROM applications WHERE status='interview_scheduled') * 100.0
      / NULLIF((SELECT COUNT(*) FROM applications),0), 1
    )                                                                        AS interview_rate_pct,
    ROUND(
      (SELECT COUNT(*) FROM applications WHERE status='accepted') * 100.0
      / NULLIF((SELECT COUNT(*) FROM applications),0), 1
    )                                                                        AS placement_rate_pct;

-- -------------------------------------------------------
-- VIEW 10: vw_skill_demand  (admin-reports – top required skills)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_skill_demand AS
SELECT
    sk.skill_id,
    sk.skill_name,
    sk.category,
    COUNT(DISTINCT js.job_id)  AS jobs_requiring,
    COUNT(DISTINCT ss.student_id) AS students_with_skill
FROM skills sk
LEFT JOIN job_skills     js ON sk.skill_id = js.skill_id
LEFT JOIN student_skills ss ON sk.skill_id = ss.skill_id
GROUP BY sk.skill_id, sk.skill_name, sk.category
ORDER BY jobs_requiring DESC;

-- ==============================================================
--  VERIFY  (quick row counts – run to confirm correct import)
-- ==============================================================
SELECT 'users'            AS tbl, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'students',             COUNT(*) FROM students
UNION ALL SELECT 'advisors',             COUNT(*) FROM advisors
UNION ALL SELECT 'employers',            COUNT(*) FROM employers
UNION ALL SELECT 'admins',               COUNT(*) FROM admins
UNION ALL SELECT 'skills',               COUNT(*) FROM skills
UNION ALL SELECT 'student_skills',       COUNT(*) FROM student_skills
UNION ALL SELECT 'job_postings',         COUNT(*) FROM job_postings
UNION ALL SELECT 'job_skills',           COUNT(*) FROM job_skills
UNION ALL SELECT 'applications',         COUNT(*) FROM applications
UNION ALL SELECT 'interviews',           COUNT(*) FROM interviews
UNION ALL SELECT 'advising_notes',       COUNT(*) FROM advising_notes;

-- Expected:  users=10 | students=4 | advisors=2 | employers=3 | admins=1
--            skills=15 | student_skills=22 | job_postings=6 | job_skills=18
--            applications=8 | interviews=2 | advising_notes=8

SELECT * FROM vw_admin_summary;
-- Expected:  total_students=4 | total_advisors=2 | total_employers=3
--            active_jobs=6 | total_applications=8 | scheduled_interviews=2
--            placements=0 | total_notes=8 | pending_verifications=1
--            interview_rate_pct=25.0 | placement_rate_pct=0.0
