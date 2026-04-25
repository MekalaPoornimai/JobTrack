-- ==============================================================
--  JobTrack – Streamlit Query Reference
--  Central Michigan University (CMU)
--
--  PURPOSE:  All SELECT / INSERT / UPDATE queries organised
--            by Streamlit page.  Use with Python mysql-connector:
--
--      import mysql.connector
--      conn = mysql.connector.connect(
--          host="localhost", user="root",
--          password="your_password", database="jobtrack_db"
--      )
--      cursor = conn.cursor(dictionary=True)
--      cursor.execute(QUERY, (param1, param2, ...))
--      rows = cursor.fetchall()
--
--  Parameters use %s placeholder (mysql-connector style).
--  Replace %s with the actual value in Python.
-- ==============================================================


-- ==============================================================
-- 0.  AUTHENTICATION  (sl-login.html)
-- ==============================================================

-- 0.1  Verify login  → returns user_id, role, first_name, last_name
SELECT  user_id, first_name, last_name, email, role, is_active
FROM    users
WHERE   email = %s
  AND   is_active = TRUE;
-- Python: cursor.execute(q, (email_input,))
-- Then verify password_hash with bcrypt.checkpw()

-- 0.2  Fetch role-specific profile after login
--      Replace %s with user_id returned from 0.1
-- For Student:
SELECT  s.student_id, s.major, s.graduation_year, s.gpa,
        s.profile_complete_pct, s.resume_url, s.linkedin_url
FROM    students s
WHERE   s.user_id = %s;

-- For Advisor:
SELECT  advisor_id, department, office_location, specialization
FROM    advisors
WHERE   user_id = %s;

-- For Employer:
SELECT  employer_id, company_name, industry, location, is_verified
FROM    employers
WHERE   user_id = %s;

-- For Admin:
SELECT  admin_id, department
FROM    admins
WHERE   user_id = %s;


-- ==============================================================
-- 1.  STUDENT DASHBOARD  (sl-student-dashboard.html)
-- ==============================================================

-- 1.1  All metrics for one student (4 metric cards + pipeline)
SELECT  *
FROM    vw_student_dashboard_metrics
WHERE   student_id = %s;
-- Returns: total_applications, cnt_applied, cnt_under_review,
--          cnt_interview, cnt_offer, cnt_accepted, cnt_rejected,
--          active_job_count, scheduled_interviews, profile_complete_pct

-- 1.2  Recent applications (last 5) for the Recent Applications table
SELECT  sa.application_id,
        sa.job_title,
        sa.company_name,
        sa.job_type,
        sa.application_status,
        sa.applied_at
FROM    vw_student_applications sa
WHERE   sa.student_id = %s
ORDER   BY sa.applied_at DESC
LIMIT   5;

-- 1.3  My advisor info
SELECT  CONCAT(u.first_name, ' ', u.last_name) AS advisor_name,
        adv.specialization,
        adv.office_location,
        adv.phone,
        u.email AS advisor_email
FROM    student_advisor_assignments saa
JOIN    advisors adv ON saa.advisor_id = adv.advisor_id
JOIN    users    u   ON adv.user_id    = u.user_id
WHERE   saa.student_id = %s
  AND   saa.is_active  = TRUE
LIMIT   1;

-- 1.4  My skills
SELECT  sk.skill_id, sk.skill_name, sk.category
FROM    student_skills ss
JOIN    skills sk ON ss.skill_id = sk.skill_id
WHERE   ss.student_id = %s
ORDER   BY sk.category, sk.skill_name;

-- 1.5  Latest 2 advisor notes (right panel)
SELECT  n.note_id, n.note_type, n.note_content, n.created_at
FROM    advising_notes n
JOIN    student_advisor_assignments saa ON n.advisor_id = saa.advisor_id
WHERE   n.student_id   = %s
  AND   n.is_private   = FALSE
ORDER   BY n.created_at DESC
LIMIT   2;

-- 1.6  Recommended jobs matching student's skills
SELECT  DISTINCT jp.job_id, jp.title, em.company_name, jp.location,
        jp.job_type, jp.salary_min, jp.salary_max, jp.application_deadline,
        COUNT(DISTINCT js.skill_id) AS matching_skills
FROM    job_postings jp
JOIN    employers   em ON jp.employer_id = em.employer_id
JOIN    job_skills  js ON jp.job_id      = js.job_id
JOIN    student_skills ss ON js.skill_id = ss.skill_id
WHERE   ss.student_id = %s
  AND   jp.status     = 'active'
  AND   jp.job_id NOT IN (
        SELECT job_id FROM applications WHERE student_id = %s
  )
GROUP   BY jp.job_id, jp.title, em.company_name, jp.location,
           jp.job_type, jp.salary_min, jp.salary_max, jp.application_deadline
ORDER   BY matching_skills DESC
LIMIT   5;


-- ==============================================================
-- 2.  BROWSE JOBS  (sl-student-jobs.html)
-- ==============================================================

-- 2.1  All active job postings with required skills (JSON-aggregated)
SELECT  jp.job_id,
        jp.title,
        em.company_name,
        em.industry,
        jp.location,
        jp.job_type,
        jp.salary_min,
        jp.salary_max,
        jp.application_deadline,
        jp.posted_at,
        GROUP_CONCAT(sk.skill_name ORDER BY sk.skill_name SEPARATOR ', ')
            AS required_skills,
        -- 1 if student already applied, 0 otherwise
        MAX(CASE WHEN a.student_id = %s THEN 1 ELSE 0 END) AS already_applied
FROM    job_postings jp
JOIN    employers   em ON jp.employer_id = em.employer_id
LEFT JOIN job_skills  js ON jp.job_id  = js.job_id
LEFT JOIN skills      sk ON js.skill_id = sk.skill_id
LEFT JOIN applications a ON jp.job_id   = a.job_id
WHERE   jp.status = 'active'
GROUP   BY jp.job_id, jp.title, em.company_name, em.industry,
           jp.location, jp.job_type, jp.salary_min, jp.salary_max,
           jp.application_deadline, jp.posted_at
ORDER   BY jp.posted_at DESC;
-- Python: pass student_id for the already_applied flag

-- 2.2  Filter jobs by type  (dropdown: All / internship / full-time / …)
SELECT  jp.job_id, jp.title, em.company_name, jp.location,
        jp.job_type, jp.salary_min, jp.salary_max, jp.application_deadline
FROM    job_postings jp
JOIN    employers em ON jp.employer_id = em.employer_id
WHERE   jp.status   = 'active'
  AND   jp.job_type = %s       -- e.g. 'internship'
ORDER   BY jp.posted_at DESC;

-- 2.3  Search jobs by keyword (title or company)
SELECT  jp.job_id, jp.title, em.company_name, jp.location,
        jp.job_type, jp.salary_min, jp.salary_max, jp.application_deadline
FROM    job_postings jp
JOIN    employers em ON jp.employer_id = em.employer_id
WHERE   jp.status = 'active'
  AND   (jp.title LIKE %s OR em.company_name LIKE %s)
ORDER   BY jp.posted_at DESC;
-- Python: cursor.execute(q, (f'%{keyword}%', f'%{keyword}%'))

-- 2.4  Job detail (single job + skills) for job detail card
SELECT  jp.*,
        em.company_name, em.industry, em.website, em.location AS company_location,
        GROUP_CONCAT(sk.skill_name SEPARATOR ', ') AS required_skills
FROM    job_postings jp
JOIN    employers em ON jp.employer_id = em.employer_id
LEFT JOIN job_skills js ON jp.job_id   = js.job_id
LEFT JOIN skills     sk ON js.skill_id = sk.skill_id
WHERE   jp.job_id = %s
GROUP   BY jp.job_id, em.company_name, em.industry, em.website, em.location;


-- ==============================================================
-- 3.  MY APPLICATIONS  (sl-student-applications.html)
-- ==============================================================

-- 3.1  All applications for a student (full list with details)
SELECT  a.application_id,
        jp.job_id,
        jp.title          AS job_title,
        em.company_name,
        jp.job_type,
        jp.location,
        a.status          AS application_status,
        a.applied_at,
        a.updated_at,
        i.scheduled_date,
        i.scheduled_time,
        i.interview_type,
        i.location_or_link
FROM    applications a
JOIN    job_postings  jp ON a.job_id        = jp.job_id
JOIN    employers     em ON jp.employer_id  = em.employer_id
LEFT JOIN interviews  i  ON a.application_id = i.application_id
                         AND i.status = 'scheduled'
WHERE   a.student_id = %s
ORDER   BY a.applied_at DESC;

-- 3.2  Status counts for tab badges
SELECT  status, COUNT(*) AS cnt
FROM    applications
WHERE   student_id = %s
GROUP   BY status;

-- 3.3  Filter applications by status (tab click)
SELECT  a.application_id, jp.title AS job_title,
        em.company_name, jp.job_type,
        a.status, a.applied_at
FROM    applications a
JOIN    job_postings jp ON a.job_id       = jp.job_id
JOIN    employers    em ON jp.employer_id = em.employer_id
WHERE   a.student_id = %s
  AND   a.status     = %s     -- e.g. 'under_review'
ORDER   BY a.applied_at DESC;

-- 3.4  Submit new application (INSERT)
INSERT INTO applications (student_id, job_id, cover_letter, status)
VALUES (%s, %s, %s, 'applied');
-- Python: cursor.execute(q, (student_id, job_id, cover_letter_text))

-- 3.5  Withdraw application (UPDATE)
UPDATE  applications
SET     status = 'withdrawn', updated_at = NOW()
WHERE   application_id = %s
  AND   student_id     = %s;   -- security: ensure student owns the record


-- ==============================================================
-- 4.  INTERVIEWS  (sl-student-interviews.html)
-- ==============================================================

-- 4.1  All scheduled interviews for a student
SELECT  i.interview_id,
        jp.title          AS job_title,
        em.company_name,
        i.scheduled_date,
        i.scheduled_time,
        i.interview_type,
        i.location_or_link,
        i.duration_minutes,
        i.status,
        i.prep_notes
FROM    interviews   i
JOIN    applications a  ON i.application_id = a.application_id
JOIN    job_postings jp ON a.job_id         = jp.job_id
JOIN    employers    em ON jp.employer_id   = em.employer_id
WHERE   a.student_id = %s
  AND   i.status IN ('scheduled', 'rescheduled')
ORDER   BY i.scheduled_date ASC, i.scheduled_time ASC;

-- 4.2  Interview metrics for the student
SELECT  COUNT(*)                               AS total_scheduled,
        SUM(status = 'completed')             AS total_completed,
        SUM(status = 'cancelled')             AS total_cancelled
FROM    interviews i
JOIN    applications a ON i.application_id = a.application_id
WHERE   a.student_id = %s;

-- 4.3  Update prep notes (student edits their prep checklist)
UPDATE  interviews
SET     prep_notes = %s, updated_at = NOW()
WHERE   interview_id  = %s
  AND   application_id IN (
        SELECT application_id FROM applications WHERE student_id = %s
  );


-- ==============================================================
-- 5.  STUDENT PROFILE  (sl-student-profile.html)
-- ==============================================================

-- 5.1  Load full profile
SELECT  u.first_name, u.last_name, u.email,
        s.student_number, s.major, s.graduation_year,
        s.gpa, s.phone, s.bio,
        s.resume_url, s.linkedin_url, s.portfolio_url,
        s.profile_complete_pct
FROM    students s
JOIN    users    u ON s.user_id = u.user_id
WHERE   s.student_id = %s;

-- 5.2  Load student skills (for skill chips editor)
SELECT  sk.skill_id, sk.skill_name, sk.category
FROM    student_skills ss
JOIN    skills sk ON ss.skill_id = sk.skill_id
WHERE   ss.student_id = %s;

-- 5.3  Load ALL available skills (for add-skill dropdown)
SELECT  skill_id, skill_name, category
FROM    skills
ORDER   BY category, skill_name;

-- 5.4  Update basic profile info
UPDATE  users
SET     first_name = %s, last_name = %s, updated_at = NOW()
WHERE   user_id = %s;

UPDATE  students
SET     major            = %s,
        graduation_year  = %s,
        gpa              = %s,
        phone            = %s,
        bio              = %s,
        resume_url       = %s,
        linkedin_url     = %s,
        portfolio_url    = %s,
        profile_complete_pct = %s
WHERE   student_id = %s;

-- 5.5  Add a skill to student profile
INSERT IGNORE INTO student_skills (student_id, skill_id)
VALUES (%s, %s);

-- 5.6  Remove a skill from student profile
DELETE FROM student_skills
WHERE student_id = %s AND skill_id = %s;


-- ==============================================================
-- 6.  ADVISOR DASHBOARD  (sl-advisor-dashboard.html)
-- ==============================================================

-- 6.1  Advisor dashboard metrics (4 metric cards)
SELECT  *
FROM    vw_advisor_dashboard_metrics
WHERE   advisor_id = %s;
-- Returns: total_students, total_applications, interviews_this_week, total_notes

-- 6.2  Student overview table  (all students assigned to advisor)
SELECT  *
FROM    vw_advisor_students
WHERE   advisor_id = %s
ORDER   BY total_applications DESC;

-- 6.3  Application status breakdown (progress bars / chart)
SELECT  a.status, COUNT(*) AS cnt
FROM    applications a
JOIN    students     s ON a.student_id = s.student_id
JOIN    student_advisor_assignments saa ON s.student_id = saa.student_id
WHERE   saa.advisor_id = %s
  AND   saa.is_active  = TRUE
GROUP   BY a.status;

-- 6.4  Advisor's notes summary (recent 5 for dashboard feed)
SELECT  n.note_id,
        CONCAT(su.first_name, ' ', su.last_name) AS student_name,
        n.note_type, n.note_content, n.created_at
FROM    advising_notes n
JOIN    students s ON n.student_id = s.student_id
JOIN    users   su ON s.user_id    = su.user_id
WHERE   n.advisor_id = %s
ORDER   BY n.created_at DESC
LIMIT   5;

-- 6.5  Quick-add note (INSERT from dashboard form)
INSERT INTO advising_notes
  (advisor_id, student_id, note_content, note_type, is_private)
VALUES (%s, %s, %s, %s, %s);
-- Python: cursor.execute(q, (advisor_id, student_id, text, note_type, is_private))


-- ==============================================================
-- 7.  ADVISOR STUDENTS  (sl-advisor-students.html)
-- ==============================================================

-- 7.1  All students assigned to advisor (full detail cards)
SELECT  vas.*,
        GROUP_CONCAT(sk.skill_name ORDER BY sk.skill_name SEPARATOR ', ')
            AS student_skills
FROM    vw_advisor_students vas
JOIN    student_skills ss ON vas.student_id = ss.student_id
JOIN    skills         sk ON ss.skill_id    = sk.skill_id
WHERE   vas.advisor_id = %s
GROUP   BY vas.student_id, vas.advisor_id, vas.advisor_name,
           vas.student_name, vas.student_email, vas.major,
           vas.graduation_year, vas.gpa, vas.profile_complete_pct,
           vas.resume_url, vas.linkedin_url,
           vas.total_applications, vas.interviews_count,
           vas.offers_count, vas.placements_count;

-- 7.2  Students with low application count (Needs Attention alert)
SELECT  CONCAT(su.first_name, ' ', su.last_name) AS student_name,
        su.email,
        COUNT(a.application_id) AS app_count
FROM    student_advisor_assignments saa
JOIN    students s  ON saa.student_id = s.student_id
JOIN    users    su ON s.user_id      = su.user_id
LEFT JOIN applications a ON s.student_id = a.student_id
WHERE   saa.advisor_id = %s
  AND   saa.is_active  = TRUE
GROUP   BY saa.student_id, su.first_name, su.last_name, su.email
HAVING  app_count < 3;   -- flag as needing attention


-- ==============================================================
-- 8.  ADVISING NOTES  (sl-advisor-notes.html)
-- ==============================================================

-- 8.1  All notes by an advisor (full list with student name)
SELECT  n.note_id,
        n.student_id,
        CONCAT(su.first_name, ' ', su.last_name) AS student_name,
        n.note_type,
        n.note_content,
        n.is_private,
        n.created_at,
        n.updated_at
FROM    advising_notes n
JOIN    students s  ON n.student_id = s.student_id
JOIN    users    su ON s.user_id    = su.user_id
WHERE   n.advisor_id = %s
ORDER   BY n.created_at DESC;

-- 8.2  Notes for a specific student (filtered view)
SELECT  n.note_id, n.note_type, n.note_content,
        n.is_private, n.created_at
FROM    advising_notes n
WHERE   n.advisor_id = %s
  AND   n.student_id = %s
ORDER   BY n.created_at DESC;

-- 8.3  Student list for Add Note dropdown
SELECT  s.student_id,
        CONCAT(su.first_name, ' ', su.last_name) AS student_name
FROM    student_advisor_assignments saa
JOIN    students s  ON saa.student_id = s.student_id
JOIN    users    su ON s.user_id      = su.user_id
WHERE   saa.advisor_id = %s
  AND   saa.is_active  = TRUE
ORDER   BY su.first_name;

-- 8.4  Add new note
INSERT INTO advising_notes
  (advisor_id, student_id, note_content, note_type, is_private)
VALUES (%s, %s, %s, %s, %s);

-- 8.5  Edit existing note
UPDATE  advising_notes
SET     note_content = %s,
        note_type    = %s,
        is_private   = %s,
        updated_at   = NOW()
WHERE   note_id    = %s
  AND   advisor_id = %s;    -- security: ensure advisor owns note

-- 8.6  Delete note
DELETE FROM advising_notes
WHERE note_id = %s AND advisor_id = %s;


-- ==============================================================
-- 9.  EMPLOYER DASHBOARD  (sl-employer-dashboard.html)
-- ==============================================================

-- 9.1  Employer dashboard metrics (4 metric cards)
SELECT  *
FROM    vw_employer_dashboard_metrics
WHERE   employer_id = %s;

-- 9.2  My job postings table
SELECT  jp.job_id,
        jp.title,
        jp.job_type,
        jp.location,
        jp.salary_min,
        jp.salary_max,
        jp.application_deadline,
        jp.status,
        COUNT(a.application_id) AS applicant_count
FROM    job_postings jp
LEFT JOIN applications a ON jp.job_id = a.job_id
WHERE   jp.employer_id = %s
GROUP   BY jp.job_id, jp.title, jp.job_type, jp.location,
           jp.salary_min, jp.salary_max, jp.application_deadline, jp.status
ORDER   BY jp.posted_at DESC;

-- 9.3  Recent applicants (last 5 across all jobs)
SELECT  vea.application_id,
        vea.applicant_name,
        vea.applicant_email,
        vea.job_title,
        vea.major,
        vea.gpa,
        vea.application_status,
        vea.applied_at
FROM    vw_employer_applicants vea
WHERE   vea.employer_id = %s
ORDER   BY vea.applied_at DESC
LIMIT   5;

-- 9.4  Upcoming interviews for employer
SELECT  i.interview_id,
        CONCAT(su.first_name, ' ', su.last_name) AS applicant_name,
        jp.title  AS job_title,
        i.scheduled_date,
        i.scheduled_time,
        i.interview_type,
        i.location_or_link
FROM    interviews   i
JOIN    applications a  ON i.application_id = a.application_id
JOIN    students     s  ON a.student_id     = s.student_id
JOIN    users        su ON s.user_id        = su.user_id
JOIN    job_postings jp ON a.job_id         = jp.job_id
WHERE   jp.employer_id = %s
  AND   i.status = 'scheduled'
ORDER   BY i.scheduled_date ASC, i.scheduled_time ASC;


-- ==============================================================
-- 10. POST A JOB  (sl-employer-post-job.html)
-- ==============================================================

-- 10.1  Insert new job posting
INSERT INTO job_postings
  (employer_id, title, description, requirements, location,
   job_type, salary_min, salary_max, application_deadline, status)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'active');
-- After INSERT: get LAST_INSERT_ID() to add job_skills

-- 10.2  Attach skills to a job posting
INSERT INTO job_skills (job_id, skill_id)
VALUES (%s, %s);
-- Call once per skill

-- 10.3  Live preview – count matching students
SELECT  COUNT(DISTINCT ss.student_id) AS matching_students
FROM    student_skills ss
WHERE   ss.skill_id IN (
        SELECT skill_id FROM job_skills WHERE job_id = %s
);
-- Before job is saved, use a subquery approach with passed skill IDs

-- 10.4  All skills list (for skill picker checkboxes)
SELECT  skill_id, skill_name, category
FROM    skills
ORDER   BY category, skill_name;

-- 10.5  Edit existing job posting
UPDATE  job_postings
SET     title                = %s,
        description          = %s,
        requirements         = %s,
        location             = %s,
        job_type             = %s,
        salary_min           = %s,
        salary_max           = %s,
        application_deadline = %s,
        updated_at           = NOW()
WHERE   job_id      = %s
  AND   employer_id = %s;   -- security

-- 10.6  Close a job posting
UPDATE  job_postings
SET     status = 'closed', updated_at = NOW()
WHERE   job_id      = %s
  AND   employer_id = %s;


-- ==============================================================
-- 11. EMPLOYER APPLICANTS  (sl-employer-applicants.html)
-- ==============================================================

-- 11.1  All applicants for employer with skill match percentage
SELECT  vea.application_id,
        vea.applicant_name,
        vea.applicant_email,
        vea.job_id,
        vea.job_title,
        vea.job_type,
        vea.major,
        vea.graduation_year,
        vea.gpa,
        vea.application_status,
        vea.applied_at,
        vea.resume_url,
        vea.linkedin_url,
        -- Skill match %
        ROUND(
          COUNT(DISTINCT CASE WHEN ss.skill_id IS NOT NULL
                THEN js.skill_id END) * 100.0
          / NULLIF(COUNT(DISTINCT js.skill_id), 0), 0
        ) AS skill_match_pct
FROM    vw_employer_applicants vea
JOIN    job_skills     js ON vea.job_id     = js.job_id
LEFT JOIN student_skills ss ON vea.student_id = ss.student_id
                           AND js.skill_id   = ss.skill_id
WHERE   vea.employer_id = %s
GROUP   BY vea.application_id, vea.applicant_name, vea.applicant_email,
           vea.job_id, vea.job_title, vea.job_type, vea.major,
           vea.graduation_year, vea.gpa, vea.application_status,
           vea.applied_at, vea.resume_url, vea.linkedin_url
ORDER   BY skill_match_pct DESC, vea.gpa DESC;

-- 11.2  Applicant counts per job (for tab badges)
SELECT  jp.job_id, jp.title, COUNT(a.application_id) AS cnt
FROM    job_postings  jp
LEFT JOIN applications a ON jp.job_id = a.job_id
WHERE   jp.employer_id = %s
GROUP   BY jp.job_id, jp.title
ORDER   BY jp.posted_at DESC;

-- 11.3  Filter applicants by job
SELECT  vea.*
FROM    vw_employer_applicants vea
WHERE   vea.employer_id = %s
  AND   vea.job_id      = %s
ORDER   BY vea.applied_at DESC;

-- 11.4  Update application status (employer review action)
UPDATE  applications
SET     status     = %s,    -- e.g. 'under_review', 'interview_scheduled', 'rejected'
        updated_at = NOW()
WHERE   application_id = %s
  AND   job_id IN (
        SELECT job_id FROM job_postings WHERE employer_id = %s
  );   -- security: employer can only update their own job applications

-- 11.5  Schedule an interview (INSERT after moving to interview_scheduled)
INSERT INTO interviews
  (application_id, scheduled_date, scheduled_time,
   interview_type, location_or_link, duration_minutes)
VALUES (%s, %s, %s, %s, %s, %s);


-- ==============================================================
-- 12. ADMIN DASHBOARD  (sl-admin-dashboard.html)
-- ==============================================================

-- 12.1  System-wide summary (all 8 metric cards)
SELECT  * FROM vw_admin_summary;

-- 12.2  Recent system activity (applications filed in last 7 days)
SELECT  a.application_id,
        CONCAT(su.first_name, ' ', su.last_name) AS student_name,
        jp.title          AS job_title,
        em.company_name,
        a.status,
        a.applied_at
FROM    applications a
JOIN    students     s  ON a.student_id    = s.student_id
JOIN    users        su ON s.user_id       = su.user_id
JOIN    job_postings jp ON a.job_id        = jp.job_id
JOIN    employers    em ON jp.employer_id  = em.employer_id
WHERE   a.applied_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER   BY a.applied_at DESC;

-- 12.3  Pending employer verifications
SELECT  em.employer_id,
        em.company_name,
        em.industry,
        em.location,
        em.website,
        u.email,
        em.created_at
FROM    employers em
JOIN    users     u ON em.user_id = u.user_id
WHERE   em.is_verified = FALSE
ORDER   BY em.created_at ASC;

-- 12.4  Verify an employer (admin action)
UPDATE  employers
SET     is_verified = TRUE
WHERE   employer_id = %s;

-- 12.5  All users list (admin user management)
SELECT  u.user_id, u.first_name, u.last_name,
        u.email, u.role, u.is_active, u.created_at
FROM    users u
ORDER   BY u.role, u.last_name;

-- 12.6  Deactivate a user account
UPDATE  users
SET     is_active = FALSE, updated_at = NOW()
WHERE   user_id = %s;

-- 12.7  All interviews (admin monitor)
SELECT  i.interview_id,
        CONCAT(su.first_name,' ',su.last_name) AS student_name,
        jp.title         AS job_title,
        em.company_name,
        i.scheduled_date, i.scheduled_time,
        i.interview_type, i.status
FROM    interviews   i
JOIN    applications a  ON i.application_id = a.application_id
JOIN    students     s  ON a.student_id     = s.student_id
JOIN    users        su ON s.user_id        = su.user_id
JOIN    job_postings jp ON a.job_id         = jp.job_id
JOIN    employers    em ON jp.employer_id   = em.employer_id
ORDER   BY i.scheduled_date DESC;


-- ==============================================================
-- 13. ADMIN REPORTS  (sl-admin-reports.html)
-- ==============================================================

-- 13.1  Overall KPI metrics
SELECT  * FROM vw_admin_summary;

-- 13.2  Applications by status (bar chart data)
SELECT  status, COUNT(*) AS cnt
FROM    applications
GROUP   BY status
ORDER   BY FIELD(status,
           'applied','under_review','interview_scheduled',
           'offer_extended','accepted','rejected','withdrawn');

-- 13.3  Applications by job posting (table)
SELECT  *
FROM    vw_admin_application_stats
ORDER   BY total_applications DESC;

-- 13.4  Applications by major (table)
SELECT  s.major,
        COUNT(DISTINCT s.student_id)              AS total_students,
        COUNT(a.application_id)                   AS total_applications,
        ROUND(AVG(s.gpa),2)                       AS avg_gpa,
        SUM(a.status = 'interview_scheduled')     AS interviews,
        SUM(a.status = 'accepted')                AS placements,
        ROUND(SUM(a.status='accepted') * 100.0
              / NULLIF(COUNT(a.application_id),0), 1) AS placement_rate_pct
FROM    students s
LEFT JOIN applications a ON s.student_id = a.student_id
GROUP   BY s.major
ORDER   BY total_applications DESC;

-- 13.5  Top applicants (students ranked by applications + GPA)
SELECT  CONCAT(su.first_name, ' ', su.last_name) AS student_name,
        su.email,
        s.major,
        s.gpa,
        COUNT(a.application_id)                   AS total_applications,
        SUM(a.status = 'interview_scheduled')     AS interviews,
        SUM(a.status = 'accepted')                AS offers_accepted
FROM    students     s
JOIN    users        su ON s.user_id    = su.user_id
LEFT JOIN applications a ON s.student_id = a.student_id
GROUP   BY s.student_id, su.first_name, su.last_name, su.email, s.major, s.gpa
ORDER   BY total_applications DESC, s.gpa DESC
LIMIT   10;

-- 13.6  Top employers by applicant volume
SELECT  em.company_name,
        em.industry,
        COUNT(DISTINCT jp.job_id)           AS active_jobs,
        COUNT(a.application_id)             AS total_applicants,
        SUM(a.status='interview_scheduled') AS interviews_given,
        em.is_verified
FROM    employers    em
LEFT JOIN job_postings jp ON em.employer_id = jp.employer_id
LEFT JOIN applications  a ON jp.job_id      = a.job_id
GROUP   BY em.employer_id, em.company_name, em.industry, em.is_verified
ORDER   BY total_applicants DESC;

-- 13.7  Most required skills (for top-skills panel)
SELECT  * FROM vw_skill_demand
LIMIT   10;

-- 13.8  Semester summary (placement & interview rates)
SELECT
    COUNT(DISTINCT s.student_id)                              AS total_students,
    COUNT(DISTINCT a.application_id)                          AS total_applications,
    ROUND(COUNT(a.application_id)*1.0
          / NULLIF(COUNT(DISTINCT s.student_id),0), 1)        AS avg_apps_per_student,
    SUM(a.status = 'interview_scheduled')                     AS total_interviews,
    ROUND(SUM(a.status='interview_scheduled') * 100.0
          / NULLIF(COUNT(a.application_id),0), 1)             AS interview_rate_pct,
    SUM(a.status = 'accepted')                                AS total_placements,
    ROUND(SUM(a.status='accepted') * 100.0
          / NULLIF(COUNT(DISTINCT s.student_id),0), 1)        AS placement_rate_pct
FROM    students s
LEFT JOIN applications a ON s.student_id = a.student_id;


-- ==============================================================
-- 14. COMMON UTILITY QUERIES
-- ==============================================================

-- 14.1  Check if a student has already applied to a job
SELECT  COUNT(*) AS already_applied
FROM    applications
WHERE   student_id = %s AND job_id = %s;

-- 14.2  Get all active job types (for filter dropdown)
SELECT  DISTINCT job_type FROM job_postings WHERE status = 'active';

-- 14.3  Get all locations (for filter dropdown)
SELECT  DISTINCT location FROM job_postings WHERE status = 'active' ORDER BY location;

-- 14.4  Get student_id from user_id (use after login)
SELECT  student_id FROM students WHERE user_id = %s;

-- 14.5  Get advisor_id from user_id
SELECT  advisor_id FROM advisors WHERE user_id = %s;

-- 14.6  Get employer_id from user_id
SELECT  employer_id FROM employers WHERE user_id = %s;

-- 14.7  Update profile_complete_pct (call after any profile edit)
UPDATE  students
SET     profile_complete_pct = ROUND((
    (CASE WHEN major           IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN graduation_year IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN gpa             IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN phone           IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN bio             IS NOT NULL AND bio != '' THEN 1 ELSE 0 END) +
    (CASE WHEN resume_url      IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN linkedin_url    IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN portfolio_url   IS NOT NULL THEN 1 ELSE 0 END)
) * 100.0 / 8, 0)
WHERE   student_id = %s;
