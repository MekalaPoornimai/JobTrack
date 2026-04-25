# ============================================================
# JobTrack - Job/Internship Application Tracking System
# BIS 698 - Information Systems Capstone | Group 5
# Central Michigan University
#
# Complete SQL Script: Schema (DDL) + Sample Data (DML)
# Demo Password for all users: Password1!
#
# Execution Order:
#   1. Drop tables (child before parent)
#   2. Create tables (parent before child)
#   3. Insert parent records first, then child records
# ============================================================

# ============================================================
# SECTION 1: DATABASE SETUP
# ============================================================
-- NOTE: On university servers, replace 'Sp2026BIS698Th05' below
--       with YOUR assigned database/username shown in Workbench.
--       On localhost, change it back to: USE jobtrack;
USE Sp2026BIS698Th05;

# ============================================================
# SECTION 2: DROP TABLES (child → parent order)
# ============================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS AdvisingNote;
DROP TABLE IF EXISTS Interview;
DROP TABLE IF EXISTS Application;
DROP TABLE IF EXISTS Job_Posting;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Advisor;
DROP TABLE IF EXISTS CareerServiceAdmin;
SET FOREIGN_KEY_CHECKS = 1;

# ============================================================
# SECTION 3: CREATE TABLES
# ============================================================

# TABLE 1: CareerServiceAdmin
# Admins who manage job postings, employers, and system reports
CREATE TABLE CareerServiceAdmin (
    AdminID          INT          NOT NULL AUTO_INCREMENT,
    first_name       VARCHAR(100) NOT NULL,
    LastName         VARCHAR(100) NOT NULL,
    Email            VARCHAR(255) NOT NULL UNIQUE,
    Password         VARCHAR(255) NOT NULL,
    Department       VARCHAR(150) DEFAULT 'Career Services',
    SecurityQuestion VARCHAR(255) NULL,
    SecurityAnswer   VARCHAR(255) NULL,
    CONSTRAINT pk_admin PRIMARY KEY (AdminID)
);

# TABLE 2: Advisor
# Academic advisors who monitor student application progress
CREATE TABLE Advisor (
    AdvisorID        INT          NOT NULL AUTO_INCREMENT,
    firstName        VARCHAR(100) NOT NULL,
    LastName         VARCHAR(100) NOT NULL,
    Email            VARCHAR(255) NOT NULL UNIQUE,
    Password         VARCHAR(255) NOT NULL,
    Department       VARCHAR(150),
    SecurityQuestion VARCHAR(255) NULL,
    SecurityAnswer   VARCHAR(255) NULL,
    CONSTRAINT pk_advisor PRIMARY KEY (AdvisorID)
);

# TABLE 3: Student
# Students who track their job and internship applications
CREATE TABLE Student (
    StudentId        INT          NOT NULL AUTO_INCREMENT,
    FirstName        VARCHAR(100) NOT NULL,
    LastName         VARCHAR(100) NOT NULL,
    Email            VARCHAR(255) NOT NULL UNIQUE,
    Password         VARCHAR(255) NOT NULL,
    Major            VARCHAR(150),
    GraduationDate   VARCHAR(20),
    AdvisorID        INT,
    SecurityQuestion VARCHAR(255) NULL,
    SecurityAnswer   VARCHAR(255) NULL,
    CONSTRAINT pk_student PRIMARY KEY (StudentId),
    CONSTRAINT fk_student_advisor
        FOREIGN KEY (AdvisorID) REFERENCES Advisor(AdvisorID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

# TABLE 4: Job_Posting
# Employer-submitted positions reviewed and published by Career Services admins
CREATE TABLE Job_Posting (
    JobID           INT          NOT NULL AUTO_INCREMENT,
    JobTitle        VARCHAR(255) NOT NULL,
    Description     TEXT,
    Posted          DATE,
    Deadline        DATE,
    CompanyName     VARCHAR(255),
    Location        VARCHAR(200),
    JobType         ENUM('Full-time','Part-time','Internship','Co-op') DEFAULT 'Internship',
    EmployerContact VARCHAR(200),
    EmployerEmail   VARCHAR(200),
    IsActive        TINYINT(1)   NOT NULL DEFAULT 1,
    AdminID         INT,
    CONSTRAINT pk_job PRIMARY KEY (JobID),
    CONSTRAINT fk_job_admin
        FOREIGN KEY (AdminID) REFERENCES CareerServiceAdmin(AdminID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

# TABLE 5: Application
# Tracks student applications to both JobTrack postings and external jobs
CREATE TABLE Application (
    ApplicationID       INT  NOT NULL AUTO_INCREMENT,
    Status              ENUM('Applied','Interview','Offer','Rejected','Withdrawn')
                        NOT NULL DEFAULT 'Applied',
    DateApplied         DATE NOT NULL,
    LastUpdated         DATE,
    StudentID           INT  NOT NULL,
    JobID               INT  NULL,                      # NULL for external applications
    ExternalJobTitle    VARCHAR(200) NULL,
    ExternalCompanyName VARCHAR(200) NULL,
    ExternalSource      VARCHAR(100) NULL,              # LinkedIn, Indeed, Handshake, etc.
    ExternalURL         VARCHAR(500) NULL,
    CONSTRAINT pk_application PRIMARY KEY (ApplicationID),
    CONSTRAINT fk_app_student
        FOREIGN KEY (StudentID) REFERENCES Student(StudentId)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_app_job
        FOREIGN KEY (JobID) REFERENCES Job_Posting(JobID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

# TABLE 6: Interview
# Interview records linked to student applications
CREATE TABLE Interview (
    InterviewID   INT          NOT NULL AUTO_INCREMENT,
    InterviewDate DATE         NOT NULL,
    InterviewType VARCHAR(100),
    MeetingLink   VARCHAR(500),
    FeedbackNotes TEXT,
    ApplicationID INT          NOT NULL,
    CONSTRAINT pk_interview PRIMARY KEY (InterviewID),
    CONSTRAINT fk_interview_app
        FOREIGN KEY (ApplicationID) REFERENCES Application(ApplicationID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

# TABLE 7: AdvisingNote
# Notes created by advisors to guide and monitor students
CREATE TABLE AdvisingNote (
    NoteID           INT     NOT NULL AUTO_INCREMENT,
    Note_content     TEXT    NOT NULL,
    DateCreated      DATE    NOT NULL,
    InterventionFlag BOOLEAN NOT NULL DEFAULT FALSE,
    StudentID        INT     NOT NULL,
    ApplicationID    INT,
    AdvisorID        INT,
    CONSTRAINT pk_note PRIMARY KEY (NoteID),
    CONSTRAINT fk_note_student
        FOREIGN KEY (StudentID) REFERENCES Student(StudentId)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_note_app
        FOREIGN KEY (ApplicationID) REFERENCES Application(ApplicationID)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_note_advisor
        FOREIGN KEY (AdvisorID) REFERENCES Advisor(AdvisorID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

# ============================================================
# SECTION 4: INSERT SAMPLE DATA
# Demo password for all accounts: Password1!
# ============================================================

# ---- TABLE 1: CareerServiceAdmin (5 records) ----
INSERT INTO CareerServiceAdmin (first_name, LastName, Email, Password, Department, SecurityQuestion, SecurityAnswer) VALUES
('Sarah',    'Mitchell', 'smitchell@cmich.edu',  'Password1!', 'Career Services',   'What is the name of your first pet?',          'fluffy'),
('James',    'Carter',   'jcarter@cmich.edu',    'Password1!', 'Career Services',   'What city were you born in?',                  'detroit'),
('Patricia', 'Wong',     'pwong@cmich.edu',       'Password1!', 'Employer Relations','What was the name of your elementary school?', 'lincoln'),
('Robert',   'Chen',     'rchen@cmich.edu',       'Password1!', 'Career Counseling', 'What is your mother\'s maiden name?',          'chen'),
('Lisa',     'Jackson',  'ljackson@cmich.edu',    'Password1!', 'Student Success',   'What city did you grow up in?',                'chicago');

# ---- TABLE 2: Advisor (8 records) ----
INSERT INTO Advisor (firstName, LastName, Email, Password, Department, SecurityQuestion, SecurityAnswer) VALUES
('Linda',   'Torres',   'ltorres@cmich.edu',   'Password1!', 'Business Information Systems', 'What is the name of your first pet?',          'buddy'),
('Mark',    'Nguyen',   'mnguyen@cmich.edu',   'Password1!', 'Computer Science',             'What city were you born in?',                  'houston'),
('Emily',   'Hassan',   'ehassan@cmich.edu',   'Password1!', 'Management',                   'What was the name of your elementary school?', 'riverside'),
('David',   'Kim',      'dkim@cmich.edu',       'Password1!', 'Data Analytics',               'What is your mother\'s maiden name?',          'park'),
('Susan',   'Patel',    'spatel@cmich.edu',     'Password1!', 'Finance',                      'What city did you grow up in?',                'mumbai'),
('John',    'Martinez', 'jmartinez@cmich.edu', 'Password1!', 'Engineering',                  'What is the name of your first pet?',          'rex'),
('Rachel',  'Brown',    'rbrown@cmich.edu',    'Password1!', 'Business Information Systems', 'What city were you born in?',                  'miami'),
('Kevin',   'Lee',      'klee@cmich.edu',       'Password1!', 'Computer Science',             'What was the name of your elementary school?', 'oakwood');

# ---- TABLE 3: Student (32 records) ----
INSERT INTO Student (FirstName, LastName, Email, Password, Major, GraduationDate, AdvisorID, SecurityQuestion, SecurityAnswer) VALUES
('Pankaj',    'Sadanala',      'psadanala@cmich.edu',      'Password1!', 'Business Information Systems', 'May 2026',      1, 'What is the name of your first pet?',          'tommy'),
('Hardhik',   'Kamatham',      'hkamatham@cmich.edu',      'Password1!', 'Computer Science',             'December 2026', 2, 'What city were you born in?',                  'hyderabad'),
('Poornimai', 'Mekala',        'pmekala@cmich.edu',        'Password1!', 'Management',                   'May 2026',      3, 'What was the name of your elementary school?', 'sunridge'),
('Shweshika', 'Ravula',        'sravula@cmich.edu',        'Password1!', 'Business Information Systems', 'May 2027',      1, 'What is your mother\'s maiden name?',          'reddy'),
('Vamsi',     'Konduru',       'vkonduru@cmich.edu',       'Password1!', 'Computer Science',             'December 2026', 2, 'What city did you grow up in?',                'vizag'),
('Alex',      'Johnson',       'ajohnson@cmich.edu',       'Password1!', 'Data Analytics',               'May 2026',      4, 'What is the name of your first pet?',          'max'),
('Priya',     'Sharma',        'psharma@cmich.edu',        'Password1!', 'Information Systems',          'May 2026',      1, 'What city were you born in?',                  'delhi'),
('Michael',   'Williams',      'mwilliams@cmich.edu',      'Password1!', 'Computer Science',             'May 2026',      2, 'What was the name of your elementary school?', 'westview'),
('Aisha',     'Thompson',      'athompson@cmich.edu',      'Password1!', 'Business Administration',      'December 2025', 3, 'What is your mother\'s maiden name?',          'johnson'),
('Ryan',      'Garcia',        'rgarcia@cmich.edu',        'Password1!', 'Finance',                      'May 2026',      5, 'What city did you grow up in?',                'austin'),
('Mei',       'Liu',           'mliu@cmich.edu',           'Password1!', 'Data Analytics',               'May 2027',      4, 'What is the name of your first pet?',          'mochi'),
('Daniel',    'Martinez',      'dmartinez@cmich.edu',      'Password1!', 'Computer Science',             'December 2026', 8, 'What city were you born in?',                  'dallas'),
('Fatima',    'Al-Hassan',     'falhassan@cmich.edu',       'Password1!', 'Management',                  'May 2026',      3, 'What was the name of your elementary school?', 'alfarabi'),
('Josh',      'Anderson',      'janderson@cmich.edu',      'Password1!', 'Business Information Systems', 'May 2027',      7, 'What is your mother\'s maiden name?',          'clark'),
('Nina',      'Patel',         'npatel@cmich.edu',         'Password1!', 'Accounting',                   'December 2025', 5, 'What city did you grow up in?',                'boston'),
('Carlos',    'Rodriguez',     'crodriguez@cmich.edu',     'Password1!', 'Computer Science',             'May 2026',      2, 'What is the name of your first pet?',          'coco'),
('Sara',      'Kim',           'skim@cmich.edu',           'Password1!', 'Information Systems',          'May 2026',      7, 'What city were you born in?',                  'seoul'),
('Marcus',    'Davis',         'mdavis@cmich.edu',         'Password1!', 'Business Administration',      'December 2026', 3, 'What was the name of your elementary school?', 'lincoln'),
('Yuki',      'Tanaka',        'ytanaka@cmich.edu',        'Password1!', 'Data Analytics',               'May 2026',      4, 'What is your mother\'s maiden name?',          'yamamoto'),
('Elena',     'Vasquez',       'evasquez@cmich.edu',       'Password1!', 'Finance',                      'May 2027',      5, 'What city did you grow up in?',                'miami'),
('Amara',     'Okonkwo',       'aokonkwo@cmich.edu',       'Password1!', 'Management',                   'May 2026',      3, 'What is the name of your first pet?',          'simba'),
('Tyler',     'Barnes',        'tbarnes@cmich.edu',        'Password1!', 'Computer Science',             'December 2026', 8, 'What city were you born in?',                  'seattle'),
('Neha',      'Gupta',         'ngupta@cmich.edu',         'Password1!', 'Business Information Systems', 'May 2026',      1, 'What was the name of your elementary school?', 'saraswati'),
('Omar',      'Hassan',        'ohassan@cmich.edu',        'Password1!', 'Computer Science',             'May 2026',      2, 'What is your mother\'s maiden name?',          'ali'),
('Brianna',   'Scott',         'bscott@cmich.edu',         'Password1!', 'Marketing',                    'December 2025', 3, 'What city did you grow up in?',                'atlanta'),
('James',     'Wilson',        'jwilson@cmich.edu',        'Password1!', 'Finance',                      'May 2026',      5, 'What is the name of your first pet?',          'charlie'),
('Ling',      'Zhang',         'lzhang@cmich.edu',         'Password1!', 'Data Analytics',               'May 2027',      4, 'What city were you born in?',                  'beijing'),
('Hannah',    'Moore',         'hmoore@cmich.edu',         'Password1!', 'Information Systems',          'May 2026',      7, 'What was the name of your elementary school?', 'meadowbrook'),
('Aaron',     'Taylor',        'ataylor@cmich.edu',        'Password1!', 'Computer Science',             'December 2026', 2, 'What is your mother\'s maiden name?',          'taylor'),
('Jasmine',   'White',         'jwhite@cmich.edu',         'Password1!', 'Business Administration',      'May 2026',      3, 'What city did you grow up in?',                'phoenix'),
('Raj',       'Krishnamurthy', 'rkrishnamurthy@cmich.edu', 'Password1!', 'Computer Science',             'May 2027',      2, 'What is the name of your first pet?',          'rocky'),
('Sofia',     'Ramirez',       'sramirez@cmich.edu',       'Password1!', 'Business Information Systems', 'December 2026', 1, 'What city were you born in?',                  'bogota');

# ---- TABLE 4: Job_Posting (32 records) ----
# Employer-submitted positions reviewed and published by CMU Career Services
INSERT INTO Job_Posting (JobTitle, Description, Posted, Deadline, CompanyName, Location, JobType, EmployerContact, EmployerEmail, IsActive, AdminID) VALUES
('Software Engineer Intern',       'Backend development using Python, Django, and AWS. Work on microservices architecture.',            '2026-01-10','2026-04-30','Accenture',           'Chicago, IL',       'Internship','Rachel Kim',       'r.kim@accenture.com',      1, 1),
('Data Analyst Intern',            'Analyze large datasets using SQL and Python. Build dashboards in Tableau and Power BI.',             '2026-01-12','2026-04-15','Deloitte',            'Detroit, MI',       'Internship','James Morgan',     'j.morgan@deloitte.com',    1, 1),
('IT Project Manager Intern',      'Support enterprise-wide system rollouts. Assist with Agile sprint planning and stakeholder reporting.','2026-01-15','2026-04-20','EY',                'Chicago, IL',       'Internship','Sarah Chen',       's.chen@ey.com',            1, 2),
('Business Analyst',               'Full-time BA role. Gather requirements, document workflows, and create process improvement plans.',  '2026-01-18','2026-04-30','Cognizant',           'Remote',            'Full-time', 'David Patel',      'd.patel@cognizant.com',    1, 1),
('Full Stack Developer Intern',    'Build React and Node.js web applications. Collaborate with design and product teams.',               '2026-01-20','2026-04-25','Infosys',             'Remote',            'Internship','Priya Sharma',     'p.sharma@infosys.com',     1, 2),
('UX Research Intern',             'Conduct user interviews, usability tests, and synthesize insights for product teams.',               '2026-01-22','2026-04-10','Google',              'San Francisco, CA', 'Internship','Mark Torres',      'm.torres@google.com',      1, 1),
('Systems Administrator Intern',   'Maintain Linux servers, configure security policies, monitor system health and uptime.',            '2026-01-25','2026-05-01','IBM',                 'Austin, TX',        'Internship','Lisa Park',        'l.park@ibm.com',           1, 2),
('Product Manager Intern',         'Work cross-functionally to define product roadmap, write PRDs, and prioritize features.',           '2026-02-01','2026-04-28','Microsoft',           'Seattle, WA',       'Internship','Kevin Lee',        'k.lee@microsoft.com',      1, 1),
('Cloud Infrastructure Intern',    'Deploy and manage AWS cloud services including EC2, S3, RDS, and Lambda.',                          '2026-02-03','2026-05-05','Amazon',              'Seattle, WA',       'Internship','Amy Johnson',      'a.johnson@amazon.com',     1, 3),
('Cybersecurity Analyst Intern',   'Monitor network traffic, conduct vulnerability assessments, and respond to security incidents.',    '2026-02-05','2026-04-20','Booz Allen Hamilton', 'Washington, DC',    'Internship','Tom Baker',        't.baker@bah.com',          1, 3),
('Machine Learning Intern',        'Develop and deploy ML models for customer segmentation and recommendation engines.',                '2026-02-07','2026-05-10','Apple',               'Cupertino, CA',     'Internship','Nina Patel',       'n.patel@apple.com',        1, 1),
('Financial Analyst',              'Full-time: analyze financial statements, build valuation models, support M&A due diligence.',       '2026-02-08','2026-04-15','JPMorgan Chase',      'New York, NY',      'Full-time', 'Chris Wilson',     'c.wilson@jpmorgan.com',    1, 5),
('Supply Chain Analyst Intern',    'Optimize procurement processes, analyze vendor performance, and improve logistics operations.',     '2026-02-10','2026-04-30','Procter & Gamble',    'Cincinnati, OH',    'Internship','Sandra Lee',       's.lee@pg.com',             1, 4),
('Software QA Engineer Intern',    'Design and execute test plans, automate regression tests using Selenium and Pytest.',               '2026-02-12','2026-05-01','Salesforce',          'San Francisco, CA', 'Internship','Ryan Clark',       'r.clark@salesforce.com',   1, 2),
('Data Engineer Intern',           'Build ETL pipelines using Apache Spark, Kafka, and Databricks. Work with petabyte-scale data.',    '2026-02-14','2026-05-15','Meta',                'Menlo Park, CA',    'Internship','Anita Kumar',      'a.kumar@meta.com',         1, 1),
('HR Technology Analyst Intern',   'Support HRIS implementation, automate HR processes, and build employee analytics dashboards.',     '2026-02-15','2026-04-25','General Electric',    'Boston, MA',        'Internship','Dan Harris',       'd.harris@ge.com',          1, 4),
('Marketing Analytics Intern',     'Analyze campaign performance using Google Analytics. Build attribution models in Python.',          '2026-02-17','2026-04-20','Procter & Gamble',    'Cincinnati, OH',    'Internship','Sandra Lee',       's.lee@pg.com',             1, 1),
('DevOps Engineer Intern',         'Implement CI/CD pipelines, manage Docker/Kubernetes infrastructure, and support deployments.',      '2026-02-18','2026-05-10','Netflix',             'Los Gatos, CA',     'Internship','Emily Zhou',       'e.zhou@netflix.com',       1, 2),
('Business Intelligence Analyst',  'Full-time: design and maintain BI dashboards, write complex SQL queries, support data governance.','2026-02-20','2026-05-01','Target',              'Minneapolis, MN',   'Full-time', 'Greg White',       'g.white@target.com',       1, 4),
('Mobile App Developer Intern',    'Build iOS and Android features using React Native. Implement RESTful API integrations.',            '2026-02-22','2026-05-05','Uber',                'San Francisco, CA', 'Internship','Maria Garcia',     'm.garcia@uber.com',        1, 2),
('Investment Banking Analyst',     'Full-time: financial modeling, pitch book preparation, and client presentations.',                  '2026-02-23','2026-04-30','Goldman Sachs',       'New York, NY',      'Full-time', 'Brian Foster',     'b.foster@gs.com',          1, 5),
('Operations Research Analyst',    'Apply quantitative methods to optimize supply chain, logistics, and resource allocation.',          '2026-02-25','2026-05-01','FedEx',               'Memphis, TN',       'Full-time', 'Susan Hill',       's.hill@fedex.com',         1, 4),
('Information Security Intern',    'Conduct penetration testing, review security policies, and assist with SOC 2 compliance.',         '2026-02-26','2026-04-30','Cisco',               'San Jose, CA',      'Internship','Robert Kim',       'r.kim@cisco.com',          1, 3),
('Actuarial Analyst Intern',       'Apply statistical models to insurance risk assessment. Work with large claims datasets.',           '2026-02-28','2026-05-15','Allstate Insurance',  'Northbrook, IL',    'Internship','Laura Evans',      'l.evans@allstate.com',     1, 5),
('ERP Systems Analyst Intern',     'Support SAP ERP implementation, gather user requirements, and develop training materials.',        '2026-03-01','2026-05-10','Ford Motor Company',  'Dearborn, MI',      'Co-op',     'Michael Scott',    'm.scott@ford.com',         1, 4),
('Robotics Software Intern',       'Develop control algorithms and simulation environments for autonomous industrial robots.',          '2026-03-03','2026-05-20','Tesla',               'Austin, TX',        'Internship','Erika Davis',      'e.davis@tesla.com',        1, 2),
('Healthcare Data Analyst Intern', 'Analyze patient outcome data, support clinical trials reporting, ensure HIPAA compliance.',        '2026-03-05','2026-05-15','Blue Cross Blue Shield','Chicago, IL',      'Internship','Patricia Moore',   'p.moore@bcbs.com',         1, 4),
('Corporate Finance Intern',       'Support treasury operations, cash flow modeling, and capital budgeting analysis.',                 '2026-03-07','2026-05-10','Ford Motor Company',  'Dearborn, MI',      'Internship','Michael Scott',    'm.scott@ford.com',         1, 5),
('AI Research Intern',             'Implement and experiment with transformer models for NLP tasks. Publish findings internally.',     '2026-03-08','2026-05-25','Google',              'Mountain View, CA', 'Internship','Mark Torres',      'm.torres@google.com',      1, 1),
('Database Administrator Intern',  'Manage MySQL and PostgreSQL databases, optimize query performance, implement backup strategies.',  '2026-03-10','2026-05-15','Oracle',              'Austin, TX',        'Internship','James Chen',       'j.chen@oracle.com',        1, 2),
('Risk Management Analyst Intern', 'Identify financial and operational risks, build risk matrices, and prepare board-level reports.',  '2026-03-12','2026-05-20','Wells Fargo',         'Charlotte, NC',     'Internship','Karen Thompson',   'k.thompson@wellsfargo.com',1, 5),
('Talent Acquisition Intern',      'Source candidates, conduct initial screenings, and support campus recruiting programs.',           '2026-03-15','2026-05-30','Accenture',           'Chicago, IL',       'Internship','Rachel Kim',       'r.kim@accenture.com',      1, 3);

# ---- TABLE 5: Application (35 records) ----
INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID) VALUES
('Offer',      '2026-01-15', '2026-02-20', 1,  1),
('Interview',  '2026-01-16', '2026-02-08', 1,  2),
('Applied',    '2026-01-25', '2026-01-25', 1,  5),
('Rejected',   '2026-01-18', '2026-02-15', 2,  1),
('Applied',    '2026-01-20', '2026-01-20', 2,  5),
('Interview',  '2026-01-22', '2026-02-10', 2, 11),
('Applied',    '2026-01-23', '2026-01-23', 3,  3),
('Interview',  '2026-01-25', '2026-02-12', 3,  4),
('Withdrawn',  '2026-01-30', '2026-02-05', 3,  8),
('Applied',    '2026-02-01', '2026-02-01', 4,  6),
('Applied',    '2026-02-02', '2026-02-02', 4,  7),
('Offer',      '2026-01-20', '2026-02-18', 5,  5),
('Interview',  '2026-01-28', '2026-02-09', 6,  2),
('Applied',    '2026-02-03', '2026-02-03', 7,  2),
('Applied',    '2026-02-05', '2026-02-05', 7,  4),
('Interview',  '2026-01-22', '2026-02-07', 8,  1),
('Applied',    '2026-01-30', '2026-01-30', 8, 18),
('Applied',    '2026-02-01', '2026-02-01', 9,  3),
('Offer',      '2026-01-28', '2026-02-22', 9, 12),
('Interview',  '2026-02-01', '2026-02-14', 10, 12),
('Applied',    '2026-02-03', '2026-02-03', 10, 24),
('Applied',    '2026-02-05', '2026-02-05', 11, 19),
('Rejected',   '2026-01-25', '2026-02-18', 11, 2),
('Interview',  '2026-02-08', '2026-02-18', 12, 5),
('Applied',    '2026-02-10', '2026-02-10', 12, 29),
('Applied',    '2026-02-01', '2026-02-01', 13, 4),
('Withdrawn',  '2026-01-28', '2026-02-03', 13, 8),
('Applied',    '2026-02-03', '2026-02-03', 14, 16),
('Interview',  '2026-02-05', '2026-02-15', 15, 12),
('Applied',    '2026-02-06', '2026-02-06', 15, 24),
('Offer',      '2026-01-25', '2026-02-20', 16, 1),
('Applied',    '2026-02-01', '2026-02-01', 17, 19),
('Interview',  '2026-01-28', '2026-02-12', 18, 4),
('Applied',    '2026-02-08', '2026-02-08', 19, 15),
('Applied',    '2026-02-10', '2026-02-10', 20, 21);

# ---- External Applications (5 records - JobID NULL, externally tracked) ----
INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID, ExternalJobTitle, ExternalCompanyName, ExternalSource, ExternalURL) VALUES
('Applied',   '2026-02-12', '2026-02-12', 1, NULL, 'Data Science Intern',           'Spotify',       'LinkedIn',      'https://spotify.com/careers/123'),
('Interview', '2026-02-14', '2026-02-20', 2, NULL, 'Backend Engineer Intern',       'Stripe',        'Company Website','https://stripe.com/jobs/456'),
('Offer',     '2026-01-30', '2026-02-25', 5, NULL, 'Software Engineer Co-op',       'Palantir',      'Handshake',     'https://palantir.com/careers/789'),
('Applied',   '2026-02-18', '2026-02-18', 8, NULL, 'Cloud Solutions Architect Intern','Snowflake',   'Career Fair',   NULL),
('Rejected',  '2026-02-01', '2026-02-22', 10, NULL,'Investment Analyst Intern',      'BlackRock',    'Referral',      NULL);

# ---- Extended Demo: Pankaj Sadanala (StudentID=1) — 12 more apps across Oct 2025–Mar 2026 ----
# ApplicationIDs 41–52 (auto-increment follows current 40 records)
INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID, ExternalJobTitle, ExternalCompanyName, ExternalSource, ExternalURL) VALUES
('Rejected',  '2025-10-15', '2025-11-01', 1, NULL, 'Software Engineering Intern',   'Amazon',        'Handshake',     'https://amazon.jobs/en/internships'),
('Withdrawn', '2025-10-22', '2025-11-05', 1, NULL, 'Data Engineering Intern',       'Meta',          'LinkedIn',      'https://metacareers.com/'),
('Interview', '2025-11-05', '2025-11-22', 1, NULL, 'Salesforce Developer Intern',   'Salesforce',    'Company Website','https://salesforce.com/company/careers/'),
('Rejected',  '2025-11-12', '2025-12-01', 1, NULL, 'UX Engineer Intern',            'Adobe',         'Handshake',     'https://adobe.com/careers.html'),
('Interview', '2025-11-20', '2025-12-05', 1, NULL, 'Open Source Programs Intern',   'GitHub',        'LinkedIn',      'https://github.com/about/careers'),
('Applied',   '2025-12-03', '2025-12-03', 1, NULL, 'Data Analyst Intern',           'Airbnb',        'Company Website',NULL),
('Offer',     '2025-12-10', '2026-01-05', 1, NULL, 'Product Analyst Intern',        'Stripe',        'LinkedIn',      'https://stripe.com/jobs'),
('Interview', '2025-12-18', '2026-01-10', 1, NULL, 'Frontend Engineering Intern',   'Figma',         'Handshake',     'https://figma.com/careers/'),
('Applied',   '2026-01-08', '2026-01-08', 1, NULL, 'Solutions Engineer Intern',     'Twilio',        'Indeed',        'https://twilio.com/company/jobs'),
('Interview', '2026-02-25', '2026-03-08', 1, NULL, 'Merchant Analytics Intern',     'Shopify',       'LinkedIn',      'https://shopify.com/careers'),
('Applied',   '2026-03-05', '2026-03-05', 1, NULL, 'HCM Analyst Intern',            'Workday',       'Career Fair',   NULL),
('Applied',   '2026-03-15', '2026-03-15', 1, NULL, 'Platform Developer Intern',     'ServiceNow',    'Company Website','https://servicenow.com/company/careers.html');

# ---- Extended Applications: Students 21–32 + more top-company volume ----
INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID) VALUES
-- Amara Okonkwo (21) – Management
('Applied',    '2026-01-18', '2026-01-18', 21,  3),
('Interview',  '2026-01-22', '2026-02-08', 21,  4),
('Applied',    '2026-02-01', '2026-02-01', 21, 16),
-- Tyler Barnes (22) – CS
('Applied',    '2026-01-20', '2026-01-20', 22,  1),
('Interview',  '2026-01-28', '2026-02-12', 22,  5),
('Rejected',   '2026-02-05', '2026-02-20', 22, 15),
('Applied',    '2026-02-15', '2026-02-15', 22, 20),
-- Neha Gupta (23) – BIS
('Offer',      '2026-01-16', '2026-02-18', 23,  1),
('Interview',  '2026-01-25', '2026-02-10', 23,  2),
('Applied',    '2026-02-08', '2026-02-08', 23,  4),
-- Omar Hassan (24) – CS
('Applied',    '2026-01-22', '2026-01-22', 24,  5),
('Interview',  '2026-02-01', '2026-02-15', 24, 11),
('Applied',    '2026-02-10', '2026-02-10', 24, 20),
('Rejected',   '2026-01-28', '2026-02-16', 24,  1),
-- Brianna Scott (25) – Marketing
('Applied',    '2026-02-03', '2026-02-03', 25, 17),
('Interview',  '2026-02-08', '2026-02-20', 25, 19),
('Applied',    '2026-02-14', '2026-02-14', 25,  3),
-- James Wilson (26) – Finance
('Applied',    '2026-01-20', '2026-01-20', 26, 12),
('Interview',  '2026-01-28', '2026-02-12', 26, 24),
('Offer',      '2026-02-01', '2026-02-28', 26, 21),
-- Ling Zhang (27) – Data Analytics
('Applied',    '2026-01-22', '2026-01-22', 27,  2),
('Interview',  '2026-02-01', '2026-02-14', 27,  6),
('Applied',    '2026-02-10', '2026-02-10', 27, 15),
('Withdrawn',  '2026-01-30', '2026-02-06', 27,  7),
-- Hannah Moore (28) – Information Systems
('Applied',    '2026-02-05', '2026-02-05', 28,  4),
('Interview',  '2026-02-12', '2026-02-22', 28,  5),
('Applied',    '2026-02-18', '2026-02-18', 28, 28),
-- Aaron Taylor (29) – CS
('Interview',  '2026-01-25', '2026-02-10', 29,  1),
('Applied',    '2026-02-01', '2026-02-01', 29, 20),
('Rejected',   '2026-01-30', '2026-02-18', 29,  8),
-- Jasmine White (30) – Business Administration
('Applied',    '2026-02-08', '2026-02-08', 30,  4),
('Interview',  '2026-02-14', '2026-02-25', 30, 19),
('Applied',    '2026-02-20', '2026-02-20', 30, 16),
-- Raj Krishnamurthy (31) – CS
('Applied',    '2026-01-18', '2026-01-18', 31,  5),
('Interview',  '2026-01-26', '2026-02-09', 31,  1),
('Offer',      '2026-02-01', '2026-02-24', 31, 15),
('Applied',    '2026-02-10', '2026-02-10', 31, 20),
-- Sofia Ramirez (32) – BIS
('Applied',    '2026-01-20', '2026-01-20', 32,  2),
('Interview',  '2026-01-28', '2026-02-12', 32,  4),
('Applied',    '2026-02-05', '2026-02-05', 32,  5),
('Rejected',   '2026-01-25', '2026-02-14', 32,  3);

# ---- TABLE 6: Interview (32 records) ----
INSERT INTO Interview (InterviewDate, InterviewType, MeetingLink, FeedbackNotes, ApplicationID) VALUES
('2026-02-05', 'Video',    'https://zoom.us/j/111111111',    'Strong technical Python skills. Excellent communication. Moving to final round.',         1),
('2026-02-07', 'Phone',    NULL,                             'Good understanding of data analysis workflow. Proceed to technical interview.',           2),
('2026-02-10', 'On-site',  NULL,                             'Impressive portfolio and leadership experience. Final round pending decision.',           6),
('2026-02-09', 'Video',    'https://meet.google.com/abc-def','Demonstrated strategic thinking and cross-functional collaboration skills.',              8),
('2026-02-12', 'Technical','https://zoom.us/j/222222222',    'Strong coding assessment. Answered all algorithm questions correctly.',                  12),
('2026-02-14', 'Panel',    'https://teams.microsoft.com/xyz','Mixed feedback from panel. Strong technical skills but needs improvement in communication.',18),
('2026-02-15', 'Phone',    NULL,                             'Initial screening complete. Background aligns with role requirements.',                  19),
('2026-02-16', 'Video',    'https://zoom.us/j/333333333',    'Excellent case study performance. Recommended for offer stage.',                        20),
('2026-02-18', 'On-site',  NULL,                             'Toured the facility. Met team members. Very positive interaction throughout.',           24),
('2026-02-11', 'Technical','https://codesignal.com/test/001','Completed coding challenge in 40 minutes. Clean, well-commented code.',                  29),
('2026-02-13', 'Video',    'https://zoom.us/j/444444444',    'Strong analytical background. Good questions asked about team culture.',                  33),
('2026-02-20', 'Phone',    NULL,                             'Preliminary screening passed. Scheduling technical round.',                             2),
('2026-02-22', 'Video',    'https://meet.google.com/ghi-jkl','Candidate demonstrated deep knowledge of machine learning frameworks.',                   6),
('2026-02-17', 'On-site',  NULL,                             'Hands-on demonstration was impressive. Team liked the candidate.',                       8),
('2026-02-19', 'Technical','https://hackerrank.com/test/002','Passed all algorithmic challenges. Exceptional problem-solving speed.',                  12),
('2026-02-21', 'Panel',    'https://teams.microsoft.com/uvw','Strong presentation skills. Panel unanimously recommended for next round.',               18),
('2026-02-23', 'Video',    'https://zoom.us/j/555555555',    'Showed excellent knowledge of financial modeling and DCF analysis.',                     20),
('2026-02-24', 'Phone',    NULL,                             'First contact completed. Candidate is enthusiastic and well-prepared.',                  24),
('2026-02-25', 'Video',    'https://zoom.us/j/666666666',    'Strong understanding of cloud services and infrastructure-as-code concepts.',             29),
('2026-02-26', 'Technical','https://codesignal.com/test/003','SQL and Python coding test completed with high score.',                                   33),
('2026-02-27', 'On-site',  NULL,                             'Impressive research background and passion for AI applications.',                         24),
('2026-02-28', 'Video',    'https://meet.google.com/mno-pqr','Good understanding of devops practices and CI/CD pipelines.',                             29),
('2026-03-01', 'Panel',    'https://teams.microsoft.com/rst','Panel agreed the candidate is a strong cultural and technical fit.',                      33),
('2026-03-02', 'Phone',    NULL,                             'Background check initiated. References contacted.',                                       1),
('2026-03-03', 'Video',    'https://zoom.us/j/777777777',    'Excellent presentation of capstone project. Team was highly impressed.',                   2),
('2026-03-04', 'Technical','https://hackerrank.com/test/003','Completed full-stack coding exercise. React and Node.js skills confirmed.',                6),
('2026-03-05', 'On-site',  NULL,                             'Team lunch included. Candidate showed excellent interpersonal skills.',                    8),
('2026-03-06', 'Video',    'https://zoom.us/j/888888888',    'Demonstrated strong knowledge of supply chain optimization algorithms.',                  12),
('2026-03-07', 'Phone',    NULL,                             'Compensation expectations discussed and aligned with budget.',                            19),
('2026-03-08', 'Technical','https://codesignal.com/test/004','Outstanding performance on the machine learning assessment.',                             20),
('2026-03-09', 'Panel',    'https://teams.microsoft.com/vwx','Cross-functional panel gave positive feedback. Hiring manager to decide.',                24),
('2026-03-10', 'Video',    'https://zoom.us/j/999999999',    'Candidate asked insightful questions. Shows genuine interest in the company mission.',     29);

# ---- Interviews for Pankaj Sadanala extended demo apps (AppIDs 43,45,47,48,50) ----
INSERT INTO Interview (InterviewDate, InterviewType, MeetingLink, FeedbackNotes, ApplicationID) VALUES
('2025-11-22', 'Video',    'https://zoom.us/j/sf101010',     'Strong Salesforce platform knowledge. Discussed Apex and LWC experience. Moving to next round.', 43),
('2025-12-05', 'Phone',    NULL,                              'Reviewed open-source contributions on GitHub profile. Panel impressed with project breadth.',     45),
('2026-01-02', 'Technical','https://zoom.us/j/stripe202',    'Excellent case study on payment infrastructure analytics. Offer extended same day.',              47),
('2026-01-10', 'On-site',  NULL,                              'Toured Figma NYC office. Whiteboard session on React component architecture. Very positive.',     48),
('2026-03-08', 'Video',    'https://meet.google.com/shp-xyz', 'Discussed e-commerce data models and retention metrics. Strong SQL skills demonstrated.',        50);

# ---- TABLE 7: AdvisingNote (33 records) ----
INSERT INTO AdvisingNote (Note_content, DateCreated, InterventionFlag, StudentID, ApplicationID, AdvisorID) VALUES
('Pankaj received an offer from Accenture. Discussed negotiation strategies and total compensation package.',              '2026-02-21', FALSE, 1,  1,  1),
('Pankaj is making excellent progress with 3 active applications. No intervention needed at this time.',                   '2026-02-15', FALSE, 1, NULL, 1),
('Reviewed Pankaj''s resume — recommended quantifying achievements and adding AWS certification to skills section.',        '2026-02-08', FALSE, 1,  2,  1),
('Hardhik was rejected from Accenture. Counseled on resume gaps and encouraged to apply to at least 5 more positions.',   '2026-02-16', TRUE,  2,  4,  2),
('Hardhik''s ML interview at Apple is scheduled. Advised reviewing PyTorch and scikit-learn documentation.',               '2026-02-12', FALSE, 2,  6,  2),
('Poornimai needs to increase application volume. Currently at 2 apps — target is 8 by end of semester.',                  '2026-02-10', TRUE,  3, NULL, 3),
('Poornimai is preparing for the EY interview. Reviewed common PM interview question types together.',                     '2026-02-14', FALSE, 3,  8,  3),
('Shweshika has only submitted 2 applications — flagged for immediate follow-up meeting.',                                  '2026-02-06', TRUE,  4, NULL, 1),
('Met with Shweshika to review job search strategy. Set goal: 2 new applications per week until deadline.',                '2026-02-13', FALSE, 4, NULL, 1),
('Vamsi received an offer from Infosys. Graduation pathway and start-date discussion scheduled.',                           '2026-02-20', FALSE, 5,  12, 2),
('Vamsi''s interview performance at Infosys was outstanding. Recommended accepting the offer.',                             '2026-02-19', FALSE, 5,  12, 2),
('Alex applied to Deloitte Data Analyst — application looks strong. Encouraged to follow up in 2 weeks.',                  '2026-02-11', FALSE, 6,  13, 4),
('Priya just started applying — only 2 applications so far. Follow up in 2 weeks for progress check.',                     '2026-02-07', FALSE, 7, NULL, 1),
('Priya needs to diversify job types — advised applying to both full-time and internship positions.',                       '2026-02-14', TRUE,  7, NULL, 1),
('Michael has strong technical skills but needs to improve on behavioral questions using STAR method.',                     '2026-02-08', FALSE, 8, NULL, 2),
('Michael''s phone interview with Accenture went well. Scheduled technical round for next week.',                           '2026-02-16', FALSE, 8,  16, 2),
('Aisha received an offer from JPMorgan Chase. This is an excellent outcome for a December graduate.',                     '2026-02-23', FALSE, 9,  19, 3),
('Ryan''s JPMorgan Chase interview is scheduled. Reviewed DCF modeling and LBO concepts together.',                        '2026-02-15', FALSE, 10, 20, 5),
('Ryan is strong in financial theory but needs to practice Excel modeling speed for case interviews.',                     '2026-02-10', FALSE, 10, NULL, 5),
('Mei has not applied to any positions yet — this is concerning given graduation timeline.',                                '2026-02-09', TRUE,  11, NULL, 4),
('Met with Mei. She was overwhelmed with coursework. Created a structured 4-week job search plan.',                        '2026-02-16', FALSE, 11, NULL, 4),
('Daniel''s technical interview at Infosys showed strong full-stack development skills.',                                   '2026-02-19', FALSE, 12, 24, 8),
('Fatima applied to Cognizant Business Analyst role — this aligns well with her management background.',                   '2026-02-06', FALSE, 13, 26, 3),
('Josh has been inactive for 3 weeks — no new applications. Sending follow-up email.',                                     '2026-02-18', TRUE,  14, NULL, 7),
('Nina''s interview at JPMorgan went well. She is confident and well-prepared for final round.',                            '2026-02-22', FALSE, 15, 29, 5),
('Carlos received an offer from Accenture. Outstanding technical performance throughout the process.',                     '2026-02-21', FALSE, 16, 31, 2),
('Sara needs to update her LinkedIn and GitHub profiles before applying to more positions.',                                '2026-02-12', FALSE, 17, NULL, 7),
('Marcus has strong soft skills but limited technical background. Encouraged to pursue PMP certification.',                 '2026-02-14', FALSE, 18, NULL, 3),
('Yuki''s data pipeline skills are exceptional. Recommended applying to Google and Meta data engineering roles.',           '2026-02-17', FALSE, 19, 34, 4),
('Elena plans to pursue investment banking after graduation. Reviewed IB recruitment timeline.',                            '2026-02-13', FALSE, 20, 35, 5),
('Amara has been consistently applying and has 2 interviews scheduled. Keep up the excellent momentum.',                   '2026-02-20', FALSE, 21, NULL, 3),
('Tyler''s GitHub profile has impressive open-source contributions — highlighted this in resume.',                          '2026-02-15', FALSE, 22, NULL, 8),
('Neha''s application to multiple BIS roles shows good self-awareness of career path.',                                    '2026-02-18', FALSE, 23, NULL, 1),
('Pankaj started his job search early. Reviewed 3 target companies: Amazon, Salesforce, Meta. Strategy looks solid.',        '2025-10-20', FALSE, 1, NULL, 1),
('Pankaj received interview invites from Salesforce and GitHub. Coached on behavioral interviews and STAR framework.',       '2025-11-18', FALSE, 1, 43,  1),
('Pankaj landed an offer from Stripe for Product Analyst Intern. Congratulated him — excellent outcome this early.',         '2026-01-06', FALSE, 1, 47,  1),
('Discussed Pankaj''s Accenture offer vs. Stripe offer. Advised evaluating total comp, mentorship, and learning curve.',     '2026-02-22', FALSE, 1, 1,   1),
('Pankaj is actively applying to Shopify and Workday in addition to existing pipeline. Good momentum heading into spring.',  '2026-03-10', FALSE, 1, NULL, 1);

# ============================================================
# SECTION 5: VIEWS (supporting dashboard queries)
# ============================================================

# View: Full application details
CREATE OR REPLACE VIEW vw_ApplicationDetails AS
SELECT
    a.ApplicationID,
    CONCAT(s.FirstName, ' ', s.LastName)    AS StudentName,
    s.Major,
    s.Email                                  AS StudentEmail,
    jp.JobTitle,
    jp.CompanyName,
    a.Status,
    a.DateApplied,
    a.LastUpdated,
    CONCAT(adv.firstName, ' ', adv.LastName) AS AdvisorName,
    i.InterviewDate,
    i.InterviewType,
    i.FeedbackNotes
FROM Application a
JOIN Student      s   ON a.StudentID  = s.StudentId
JOIN Job_Posting  jp  ON a.JobID      = jp.JobID
LEFT JOIN Advisor      adv ON s.AdvisorID      = adv.AdvisorID
LEFT JOIN Interview    i   ON a.ApplicationID  = i.ApplicationID;

# View: Students needing intervention
CREATE OR REPLACE VIEW vw_InterventionList AS
SELECT DISTINCT
    s.StudentId,
    CONCAT(s.FirstName, ' ', s.LastName)    AS StudentName,
    s.Email,
    s.Major,
    CONCAT(adv.firstName, ' ', adv.LastName) AS Advisor,
    an.Note_content,
    an.DateCreated
FROM AdvisingNote an
JOIN Student s   ON an.StudentID  = s.StudentId
LEFT JOIN Advisor adv ON s.AdvisorID = adv.AdvisorID
WHERE an.InterventionFlag = TRUE;

# View: Company offer rates
CREATE OR REPLACE VIEW vw_CompanyOfferRate AS
SELECT
    jp.CompanyName,
    COUNT(a.ApplicationID) AS TotalApps,
    SUM(CASE WHEN a.Status = 'Offer' THEN 1 ELSE 0 END) AS TotalOffers,
    ROUND(
        SUM(CASE WHEN a.Status = 'Offer' THEN 1 ELSE 0 END) * 100.0 / COUNT(a.ApplicationID),
        1
    ) AS OfferRatePct
FROM Application a
JOIN Job_Posting jp ON a.JobID = jp.JobID
GROUP BY jp.CompanyName
HAVING TotalApps > 0;

# ============================================================
# SECTION 6: VERIFY ROW COUNTS
# ============================================================
SELECT 'CareerServiceAdmin' AS TableName, COUNT(*) AS RecordCount FROM CareerServiceAdmin
UNION ALL SELECT 'Advisor',      COUNT(*) FROM Advisor
UNION ALL SELECT 'Student',      COUNT(*) FROM Student
UNION ALL SELECT 'Job_Posting',  COUNT(*) FROM Job_Posting
UNION ALL SELECT 'Application',  COUNT(*) FROM Application
UNION ALL SELECT 'Interview',    COUNT(*) FROM Interview
UNION ALL SELECT 'AdvisingNote', COUNT(*) FROM AdvisingNote;
