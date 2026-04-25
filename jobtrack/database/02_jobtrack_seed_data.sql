-- =============================================================
-- JOBTRACK - Job/Internship Application Tracking System
-- FILE 2: Seed Data (DML) - INSERT sample records
-- BIS 698 | Group 5
-- Run AFTER 01_jobtrack_schema.sql
-- =============================================================

USE jobtrack;

-- =============================================================
-- CareerServiceAdmin
-- =============================================================
INSERT INTO CareerServiceAdmin (first_name, LastName, Email, Password) VALUES
('Sarah',  'Mitchell',  'smitchell@university.edu',  'hashed_pw_1'),
('James',  'Carter',    'jcarter@university.edu',    'hashed_pw_2');

-- =============================================================
-- Advisor
-- =============================================================
INSERT INTO Advisor (firstName, LastName, Email, Password, Department) VALUES
('Dr. Linda',  'Torres',   'ltorres@university.edu',  'hashed_pw_a', 'Business Information Systems'),
('Prof. Mark', 'Nguyen',   'mnguyen@university.edu',  'hashed_pw_b', 'Computer Science'),
('Dr. Emily',  'Hassan',   'ehassan@university.edu',  'hashed_pw_c', 'Management');

-- =============================================================
-- Student
-- =============================================================
INSERT INTO Student (FirstName, LastName, Email, Password, Major, GraduationDate, AdvisorID) VALUES
('Pankaj',    'Sadanala',  'psadanala@university.edu',  'hashed_pw_s1', 'Business Information Systems', 'May 2026',      1),
('Hardhik',   'Kamatham',  'hkamatham@university.edu',  'hashed_pw_s2', 'Computer Science',             'December 2026', 2),
('Poornimai', 'Mekala',    'pmekala@university.edu',    'hashed_pw_s3', 'Management',                   'May 2026',      3),
('Shweshika', 'Ravula',    'sravula@university.edu',    'hashed_pw_s4', 'Business Information Systems', 'May 2027',      1),
('Vamsi',     'Konduru',   'vkonduru@university.edu',   'hashed_pw_s5', 'Computer Science',             'December 2026', 2),
('Alex',      'Johnson',   'ajohnson@university.edu',   'hashed_pw_s6', 'Data Analytics',              'May 2026',      2),
('Priya',     'Sharma',    'psharma@university.edu',    'hashed_pw_s7', 'Information Systems',          'May 2026',      1);

-- =============================================================
-- Job_Posting (AdminID 1 = Sarah Mitchell)
-- =============================================================
INSERT INTO Job_Posting (JobTitle, Description, Posted, Deadline, CompanyName, AdminID) VALUES
('Software Engineer Intern',        'Backend development with Python and AWS.',           '2026-01-10', '2026-02-28', 'Accenture',       1),
('Data Analyst Intern',             'Data wrangling, dashboards, and SQL queries.',        '2026-01-12', '2026-03-01', 'Deloitte',        1),
('IT Project Manager Intern',       'Support PM team on enterprise rollout projects.',     '2026-01-15', '2026-02-20', 'EY',              2),
('Business Analyst',                'Full-time BA role with focus on process improvement.','2026-01-18', '2026-03-15', 'Cognizant',       1),
('Full Stack Developer Intern',     'React + Node.js web development.',                    '2026-01-20', '2026-03-10', 'Infosys',         2),
('UX Research Intern',              'Conduct user interviews and usability testing.',       '2026-01-22', '2026-02-25', 'Google',          1),
('Systems Administrator Intern',    'Linux server maintenance and monitoring.',             '2026-01-25', '2026-03-05', 'IBM',             2),
('Product Manager Intern',          'Work cross-functionally to define product roadmap.',   '2026-02-01', '2026-03-20', 'Microsoft',       1);

-- =============================================================
-- Application
-- =============================================================
INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID) VALUES
('Offer',      '2026-01-15', '2026-02-10', 1, 1),
('Interview',  '2026-01-16', '2026-02-05', 1, 2),
('Applied',    '2026-01-20', '2026-01-20', 2, 5),
('Rejected',   '2026-01-18', '2026-02-08', 2, 1),
('Applied',    '2026-01-22', '2026-01-22', 3, 3),
('Interview',  '2026-01-25', '2026-02-12', 3, 4),
('Applied',    '2026-02-01', '2026-02-01', 4, 6),
('Applied',    '2026-02-02', '2026-02-02', 4, 7),
('Offer',      '2026-01-20', '2026-02-15', 5, 5),
('Interview',  '2026-01-28', '2026-02-09', 6, 8),
('Applied',    '2026-02-03', '2026-02-03', 7, 2),
('Applied',    '2026-02-05', '2026-02-05', 7, 4),
('Withdrawn',  '2026-01-30', '2026-02-07', 6, 3);

-- =============================================================
-- Interview
-- =============================================================
INSERT INTO Interview (InterviewDate, InterviewType, MeetingLink, FeedbackNotes, ApplicationID) VALUES
('2026-02-05', 'Video',    'https://zoom.us/j/111111', 'Strong technical skills, good communicator.',         1),
('2026-02-07', 'Phone',    NULL,                        'Good first round. Moving to technical interview.',    2),
('2026-02-12', 'On-site',  NULL,                        'Impressive portfolio. Final round pending.',          6),
('2026-02-09', 'Video',    'https://meet.google.com/abc','Showed leadership experience and strategic thinking.',10);

-- =============================================================
-- AdvisingNote
-- =============================================================
INSERT INTO AdvisingNote (Note_content, DateCreated, InterventionFlag, StudentID, ApplicationID, AdvisorID) VALUES
('Student received offer from Accenture. Discussed negotiation strategies.',       '2026-02-11', FALSE, 1, 1,  1),
('Pankaj is making excellent progress. No intervention needed.',                   '2026-02-12', FALSE, 1, NULL,1),
('Hardhik was rejected from Accenture. Encouraged to apply to more roles.',        '2026-02-09', TRUE,  2, 4,  2),
('Shweshika has only 2 applications so far — flagged for check-in meeting.',       '2026-02-06', TRUE,  4, NULL,1),
('Vamsi received an offer at Infosys. Graduation pathway discussion scheduled.',   '2026-02-16', FALSE, 5, 9,  2),
('Priya just started applying — follow up in 2 weeks.',                            '2026-02-06', FALSE, 7, NULL,1);
