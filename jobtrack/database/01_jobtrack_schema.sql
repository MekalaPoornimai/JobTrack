-- =============================================================
-- JOBTRACK - Job/Internship Application Tracking System
-- FILE 1: Schema (DDL) - Create all tables
-- BIS 698 | Group 5
-- =============================================================

-- Create and select the database
CREATE DATABASE IF NOT EXISTS jobtrack;
USE jobtrack;

-- =============================================================
-- TABLE 1: CareerServiceAdmin
-- Admins who manage the system, employers, and reporting
-- =============================================================
CREATE TABLE CareerServiceAdmin (
    AdminID     INT             NOT NULL AUTO_INCREMENT,
    first_name  VARCHAR(100)    NOT NULL,
    LastName    VARCHAR(100)    NOT NULL,
    Email       VARCHAR(255)    NOT NULL UNIQUE,
    Password    VARCHAR(255)    NOT NULL,          -- store bcrypt hash
    CONSTRAINT pk_admin PRIMARY KEY (AdminID)
);

-- =============================================================
-- TABLE 2: Advisor
-- Academic advisors who monitor and advise students
-- =============================================================
CREATE TABLE Advisor (
    AdvisorID   INT             NOT NULL AUTO_INCREMENT,
    firstName   VARCHAR(100)    NOT NULL,
    LastName    VARCHAR(100)    NOT NULL,
    Email       VARCHAR(255)    NOT NULL UNIQUE,
    Password    VARCHAR(255)    NOT NULL,          -- store bcrypt hash
    Department  VARCHAR(150),
    CONSTRAINT pk_advisor PRIMARY KEY (AdvisorID)
);

-- =============================================================
-- TABLE 3: Student
-- Students who track their job/internship applications
-- =============================================================
CREATE TABLE Student (
    StudentId       INT             NOT NULL AUTO_INCREMENT,
    FirstName       VARCHAR(100)    NOT NULL,
    LastName        VARCHAR(100)    NOT NULL,
    Email           VARCHAR(255)    NOT NULL UNIQUE,
    Password        VARCHAR(255)    NOT NULL,      -- store bcrypt hash
    Major           VARCHAR(150),
    GraduationDate  VARCHAR(20),                  -- e.g. "May 2026"
    AdvisorID       INT,
    CONSTRAINT pk_student   PRIMARY KEY (StudentId),
    CONSTRAINT fk_student_advisor
        FOREIGN KEY (AdvisorID) REFERENCES Advisor(AdvisorID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- =============================================================
-- TABLE 4: Job_Posting
-- Job/internship postings managed by Career Services admins
-- (Employer entity removed per project decision)
-- =============================================================
CREATE TABLE Job_Posting (
    JobID       INT             NOT NULL AUTO_INCREMENT,
    JobTitle    VARCHAR(255)    NOT NULL,
    Description TEXT,
    Posted      DATE,
    Deadline    DATE,
    CompanyName VARCHAR(255),                     -- denormalized after removing Employer
    AdminID     INT,
    CONSTRAINT pk_job       PRIMARY KEY (JobID),
    CONSTRAINT fk_job_admin
        FOREIGN KEY (AdminID) REFERENCES CareerServiceAdmin(AdminID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- =============================================================
-- TABLE 5: Application
-- Central table - student applications to job postings
-- =============================================================
CREATE TABLE Application (
    ApplicationID   INT             NOT NULL AUTO_INCREMENT,
    Status          ENUM('Applied','Interview','Offer','Rejected','Withdrawn')
                                    NOT NULL DEFAULT 'Applied',
    DateApplied     DATE            NOT NULL,
    LastUpdated     DATE,
    StudentID       INT             NOT NULL,
    JobID           INT             NOT NULL,
    CONSTRAINT pk_application   PRIMARY KEY (ApplicationID),
    CONSTRAINT fk_app_student
        FOREIGN KEY (StudentID) REFERENCES Student(StudentId)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_app_job
        FOREIGN KEY (JobID) REFERENCES Job_Posting(JobID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =============================================================
-- TABLE 6: Interview
-- Interview records linked to applications
-- =============================================================
CREATE TABLE Interview (
    InterviewID     INT             NOT NULL AUTO_INCREMENT,
    InterviewDate   DATE            NOT NULL,
    InterviewType   VARCHAR(100),                 -- e.g. Phone, Video, On-site
    MeetingLink     VARCHAR(500),
    FeedbackNotes   TEXT,
    ApplicationID   INT             NOT NULL,
    CONSTRAINT pk_interview     PRIMARY KEY (InterviewID),
    CONSTRAINT fk_interview_app
        FOREIGN KEY (ApplicationID) REFERENCES Application(ApplicationID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =============================================================
-- TABLE 7: AdvisingNote
-- Notes added by advisors for student applications
-- =============================================================
CREATE TABLE AdvisingNote (
    NoteID              INT         NOT NULL AUTO_INCREMENT,
    Note_content        TEXT        NOT NULL,
    DateCreated         DATE        NOT NULL,
    InterventionFlag    BOOLEAN     NOT NULL DEFAULT FALSE,
    StudentID           INT         NOT NULL,
    ApplicationID       INT,
    AdvisorID           INT,
    CONSTRAINT pk_note      PRIMARY KEY (NoteID),
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
