-- =============================================================
-- JOBTRACK - Job/Internship Application Tracking System
-- FILE 3: Application Queries (DML) - All key queries
-- BIS 698 | Group 5
-- Run AFTER 01 and 02 files
-- =============================================================

USE jobtrack;


-- ===========================================================
-- SECTION A: STUDENT MODULE QUERIES
-- ===========================================================

-- A1. Student Login (authenticate by email)
SELECT StudentId, FirstName, LastName, Email, Password, Major, GraduationDate, AdvisorID
FROM Student
WHERE Email = 'psadanala@university.edu';

-- A2. Student views their own applications with job details
SELECT
    a.ApplicationID,
    jp.JobTitle,
    jp.CompanyName,
    a.Status,
    a.DateApplied,
    a.LastUpdated
FROM Application a
JOIN Job_Posting jp ON a.JobID = jp.JobID
WHERE a.StudentID = 1
ORDER BY a.DateApplied DESC;

-- A3. Student adds a new application (INSERT)
INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID)
VALUES ('Applied', CURDATE(), CURDATE(), 1, 3);

-- A4. Student updates application status
UPDATE Application
SET Status = 'Interview', LastUpdated = CURDATE()
WHERE ApplicationID = 3 AND StudentID = 2;

-- A5. Student deletes an application
DELETE FROM Application
WHERE ApplicationID = 13 AND StudentID = 6;

-- A6. Student views available job postings
SELECT JobID, JobTitle, CompanyName, Description, Posted, Deadline
FROM Job_Posting
WHERE Deadline >= CURDATE()
ORDER BY Deadline ASC;

-- A7. Student views their interview schedule
SELECT
    i.InterviewID,
    jp.JobTitle,
    jp.CompanyName,
    i.InterviewDate,
    i.InterviewType,
    i.MeetingLink,
    i.FeedbackNotes
FROM Interview i
JOIN Application a  ON i.ApplicationID = a.ApplicationID
JOIN Job_Posting jp ON a.JobID = jp.JobID
WHERE a.StudentID = 1
ORDER BY i.InterviewDate ASC;

-- A8. Student application summary count by status
SELECT Status, COUNT(*) AS Total
FROM Application
WHERE StudentID = 1
GROUP BY Status;


-- ===========================================================
-- SECTION B: ADVISOR MODULE QUERIES
-- ===========================================================

-- B1. Advisor Login
SELECT AdvisorID, firstName, LastName, Email, Password, Department
FROM Advisor
WHERE Email = 'ltorres@university.edu';

-- B2. Advisor views all students in their pipeline
SELECT
    s.StudentId,
    s.FirstName,
    s.LastName,
    s.Major,
    s.GraduationDate,
    s.Email,
    COUNT(a.ApplicationID) AS TotalApplications
FROM Student s
LEFT JOIN Application a ON s.StudentId = a.StudentID
WHERE s.AdvisorID = 1
GROUP BY s.StudentId, s.FirstName, s.LastName, s.Major, s.GraduationDate, s.Email
ORDER BY s.LastName;

-- B3. Advisor views all applications for a specific student
SELECT
    a.ApplicationID,
    jp.JobTitle,
    jp.CompanyName,
    a.Status,
    a.DateApplied,
    a.LastUpdated
FROM Application a
JOIN Job_Posting jp ON a.JobID = jp.JobID
WHERE a.StudentID = 2
ORDER BY a.DateApplied DESC;

-- B4. Advisor adds an advising note with intervention flag
INSERT INTO AdvisingNote (Note_content, DateCreated, InterventionFlag, StudentID, ApplicationID, AdvisorID)
VALUES ('Student has not updated status in 3 weeks. Requires follow-up.', CURDATE(), TRUE, 4, NULL, 1);

-- B5. Advisor views all notes for a student
SELECT
    an.NoteID,
    an.Note_content,
    an.DateCreated,
    an.InterventionFlag,
    a.ApplicationID,
    jp.JobTitle
FROM AdvisingNote an
LEFT JOIN Application a  ON an.ApplicationID = a.ApplicationID
LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
WHERE an.StudentID = 1
ORDER BY an.DateCreated DESC;

-- B6. Advisor identifies students needing intervention (flagged notes)
SELECT DISTINCT
    s.StudentId,
    s.FirstName,
    s.LastName,
    s.Email,
    an.Note_content,
    an.DateCreated
FROM AdvisingNote an
JOIN Student s ON an.StudentID = s.StudentId
WHERE an.InterventionFlag = TRUE
  AND s.AdvisorID = 1
ORDER BY an.DateCreated DESC;

-- B7. Students with ZERO applications (at-risk students)
SELECT
    s.StudentId,
    s.FirstName,
    s.LastName,
    s.Email,
    s.Major,
    s.GraduationDate
FROM Student s
LEFT JOIN Application a ON s.StudentId = a.StudentID
WHERE s.AdvisorID = 1
  AND a.ApplicationID IS NULL;

-- B8. Students with fewer than 3 applications
SELECT
    s.StudentId,
    s.FirstName,
    s.LastName,
    s.Email,
    COUNT(a.ApplicationID) AS AppCount
FROM Student s
LEFT JOIN Application a ON s.StudentId = a.StudentID
WHERE s.AdvisorID = 1
GROUP BY s.StudentId, s.FirstName, s.LastName, s.Email
HAVING AppCount < 3
ORDER BY AppCount ASC;


-- ===========================================================
-- SECTION C: ADMIN MODULE QUERIES
-- ===========================================================

-- C1. Admin Login
SELECT AdminID, first_name, LastName, Email, Password
FROM CareerServiceAdmin
WHERE Email = 'smitchell@university.edu';

-- C2. Admin views all job postings
SELECT
    jp.JobID,
    jp.JobTitle,
    jp.CompanyName,
    jp.Posted,
    jp.Deadline,
    COUNT(a.ApplicationID) AS TotalApplicants
FROM Job_Posting jp
LEFT JOIN Application a ON jp.JobID = a.JobID
GROUP BY jp.JobID, jp.JobTitle, jp.CompanyName, jp.Posted, jp.Deadline
ORDER BY jp.Posted DESC;

-- C3. Admin creates a new job posting
INSERT INTO Job_Posting (JobTitle, Description, Posted, Deadline, CompanyName, AdminID)
VALUES ('Cloud Engineer Intern', 'AWS infrastructure and CI/CD pipeline support.', CURDATE(), '2026-04-01', 'Amazon', 1);

-- C4. Admin updates a job posting
UPDATE Job_Posting
SET Deadline = '2026-04-15', Description = 'Updated role: includes Kubernetes experience preferred.'
WHERE JobID = 5;

-- C5. Admin deletes a job posting
DELETE FROM Job_Posting WHERE JobID = 9;

-- C6. REPORT: Overall application funnel by status
SELECT
    Status,
    COUNT(*) AS Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS Percentage
FROM Application
GROUP BY Status
ORDER BY FIELD(Status, 'Applied', 'Interview', 'Offer', 'Rejected', 'Withdrawn');

-- C7. REPORT: Placement rate (Offers / Total applications)
SELECT
    ROUND(
        SUM(CASE WHEN Status = 'Offer' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        1
    ) AS PlacementRatePct
FROM Application;

-- C8. REPORT: Companies with highest application volume
SELECT
    jp.CompanyName,
    COUNT(a.ApplicationID) AS TotalApplications,
    SUM(CASE WHEN a.Status = 'Offer' THEN 1 ELSE 0 END) AS Offers
FROM Application a
JOIN Job_Posting jp ON a.JobID = jp.JobID
GROUP BY jp.CompanyName
ORDER BY TotalApplications DESC
LIMIT 10;

-- C9. REPORT: Application activity by month
SELECT
    DATE_FORMAT(DateApplied, '%Y-%m') AS Month,
    COUNT(*) AS Applications
FROM Application
GROUP BY Month
ORDER BY Month;

-- C10. REPORT: Students with offers (placement list)
SELECT
    s.FirstName,
    s.LastName,
    s.Major,
    s.GraduationDate,
    jp.CompanyName,
    jp.JobTitle,
    a.DateApplied
FROM Application a
JOIN Student    s  ON a.StudentID = s.StudentId
JOIN Job_Posting jp ON a.JobID   = jp.JobID
WHERE a.Status = 'Offer'
ORDER BY jp.CompanyName;

-- C11. REPORT: Advisor effectiveness - notes and intervention rates
SELECT
    adv.AdvisorID,
    CONCAT(adv.firstName, ' ', adv.LastName) AS AdvisorName,
    COUNT(an.NoteID) AS TotalNotes,
    SUM(an.InterventionFlag) AS Interventions
FROM Advisor adv
LEFT JOIN AdvisingNote an ON adv.AdvisorID = an.AdvisorID
GROUP BY adv.AdvisorID, AdvisorName
ORDER BY TotalNotes DESC;

-- C12. REPORT: Full student pipeline view (admin view all students + status)
SELECT
    s.StudentId,
    CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
    s.Major,
    s.GraduationDate,
    CONCAT(adv.firstName, ' ', adv.LastName) AS Advisor,
    COUNT(a.ApplicationID) AS TotalApps,
    SUM(CASE WHEN a.Status = 'Applied'   THEN 1 ELSE 0 END) AS Applied,
    SUM(CASE WHEN a.Status = 'Interview' THEN 1 ELSE 0 END) AS Interviews,
    SUM(CASE WHEN a.Status = 'Offer'     THEN 1 ELSE 0 END) AS Offers
FROM Student s
LEFT JOIN Application a  ON s.StudentId = a.StudentID
LEFT JOIN Advisor adv    ON s.AdvisorID = adv.AdvisorID
GROUP BY s.StudentId, StudentName, s.Major, s.GraduationDate, Advisor
ORDER BY s.LastName;


-- ===========================================================
-- SECTION D: USEFUL VIEWS
-- ===========================================================

-- D1. View: Full application details (join all major tables)
CREATE OR REPLACE VIEW vw_ApplicationDetails AS
SELECT
    a.ApplicationID,
    CONCAT(s.FirstName, ' ', s.LastName)         AS StudentName,
    s.Major,
    s.Email                                       AS StudentEmail,
    jp.JobTitle,
    jp.CompanyName,
    a.Status,
    a.DateApplied,
    a.LastUpdated,
    CONCAT(adv.firstName, ' ', adv.LastName)      AS AdvisorName,
    i.InterviewDate,
    i.InterviewType,
    i.FeedbackNotes
FROM Application a
JOIN Student     s   ON a.StudentID = s.StudentId
JOIN Job_Posting jp  ON a.JobID     = jp.JobID
LEFT JOIN Advisor     adv ON s.AdvisorID = adv.AdvisorID
LEFT JOIN Interview   i   ON a.ApplicationID = i.ApplicationID;

-- D2. View: Students needing intervention
CREATE OR REPLACE VIEW vw_InterventionList AS
SELECT DISTINCT
    s.StudentId,
    CONCAT(s.FirstName, ' ', s.LastName)         AS StudentName,
    s.Email,
    s.Major,
    CONCAT(adv.firstName, ' ', adv.LastName)      AS Advisor,
    an.Note_content,
    an.DateCreated
FROM AdvisingNote an
JOIN Student s   ON an.StudentID = s.StudentId
LEFT JOIN Advisor adv ON s.AdvisorID = adv.AdvisorID
WHERE an.InterventionFlag = TRUE;

-- D3. View: Offer rate by company
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


-- ===========================================================
-- SECTION E: SAMPLE VIEW QUERIES (use after views are created)
-- ===========================================================

-- View all application details
SELECT * FROM vw_ApplicationDetails;

-- List all intervention-flagged students
SELECT * FROM vw_InterventionList;

-- Company offer rates ranked
SELECT * FROM vw_CompanyOfferRate ORDER BY OfferRatePct DESC;
