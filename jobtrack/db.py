# ============================================================
# JobTrack - Database Layer
# BIS 698 | Group 5 | Central Michigan University
#
# All MySQL queries organized by module:
#   - Authentication
#   - Student Module
#   - Advisor Module
#   - Admin Module
#
# NOTE: Passwords stored as plain text for demonstration.
#       Production deployment should use bcrypt hashing.
# ============================================================

import mysql.connector
from mysql.connector import Error
import streamlit as st
from config import DB_CONFIG   # Edit config.py to set your MySQL password


def get_connection():
    """Create and return a MySQL database connection."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        st.error(f"❌ Database connection failed: {e}")
        st.info("💡 Make sure MySQL is running and DB_CONFIG in db.py is correct.")
        return None


def run_query(sql, params=None, fetch=True):
    """
    Execute a SQL query.
    - fetch=True  → returns list of dicts (SELECT)
    - fetch=False → executes INSERT/UPDATE/DELETE, returns lastrowid
    """
    conn = get_connection()
    if not conn:
        return [] if fetch else None
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params or ())
        if fetch:
            return cur.fetchall()
        else:
            conn.commit()
            return cur.lastrowid
    except Error as e:
        st.error(f"❌ Query error: {e}")
        return [] if fetch else None
    finally:
        conn.close()


# ============================================================
# AUTHENTICATION
# ============================================================

def authenticate(email: str, password: str):
    """
    Authenticate user against all role tables.
    Returns (role, user_id, full_name) or None if invalid.
    """
    # Check Student
    rows = run_query(
        "SELECT StudentId, FirstName, LastName FROM Student WHERE Email=%s AND Password=%s",
        (email, password)
    )
    if rows:
        r = rows[0]
        return 'student', r['StudentId'], f"{r['FirstName']} {r['LastName']}"

    # Check Advisor
    rows = run_query(
        "SELECT AdvisorID, firstName, LastName FROM Advisor WHERE Email=%s AND Password=%s",
        (email, password)
    )
    if rows:
        r = rows[0]
        return 'advisor', r['AdvisorID'], f"{r['firstName']} {r['LastName']}"

    # Check CareerServiceAdmin
    rows = run_query(
        "SELECT AdminID, first_name, LastName FROM CareerServiceAdmin WHERE Email=%s AND Password=%s",
        (email, password)
    )
    if rows:
        r = rows[0]
        return 'admin', r['AdminID'], f"{r['first_name']} {r['LastName']}"

    return None


# ============================================================
# STUDENT MODULE
# ============================================================

def get_student(student_id: int) -> dict:
    """Get full student profile including advisor info."""
    rows = run_query("""
        SELECT s.*,
               CONCAT(a.firstName, ' ', a.LastName) AS AdvisorName,
               a.Department AS AdvisorDept,
               a.Email      AS AdvisorEmail
        FROM Student s
        LEFT JOIN Advisor a ON s.AdvisorID = a.AdvisorID
        WHERE s.StudentId = %s
    """, (student_id,))
    return rows[0] if rows else None


def update_student_profile(student_id, first, last, major, grad_date):
    """Update student profile fields."""
    run_query(
        "UPDATE Student SET FirstName=%s, LastName=%s, Major=%s, GraduationDate=%s WHERE StudentId=%s",
        (first, last, major, grad_date, student_id), fetch=False
    )


def update_password(table, id_col, user_id, new_password):
    """Update password for any user role."""
    run_query(
        f"UPDATE {table} SET Password=%s WHERE {id_col}=%s",
        (new_password, user_id), fetch=False
    )


def get_active_jobs(search='', job_type='All'):
    """Browse active employer-submitted postings visible to students."""
    sql = """
        SELECT jp.*,
               (SELECT COUNT(*) FROM Application a WHERE a.JobID = jp.JobID) AS Trackers
        FROM Job_Posting jp
        WHERE jp.IsActive = 1
          AND jp.Deadline >= CURDATE()
    """
    params = []
    if search:
        sql += " AND (jp.JobTitle LIKE %s OR jp.CompanyName LIKE %s OR jp.Location LIKE %s OR jp.Description LIKE %s)"
        params.extend([f'%{search}%', f'%{search}%', f'%{search}%', f'%{search}%'])
    if job_type and job_type != 'All':
        sql += " AND jp.JobType = %s"
        params.append(job_type)
    sql += " ORDER BY jp.Deadline ASC"
    return run_query(sql, tuple(params) if params else None)


def get_all_jobs():
    """Get all job postings (for admin/advisor)."""
    return run_query("""
        SELECT jp.*,
               (SELECT COUNT(*) FROM Application a WHERE a.JobID = jp.JobID) AS Applicants
        FROM Job_Posting jp
        ORDER BY jp.Posted DESC
    """)


def already_applied(student_id, job_id) -> bool:
    """Check if student already applied to a job."""
    rows = run_query(
        "SELECT ApplicationID FROM Application WHERE StudentID=%s AND JobID=%s",
        (student_id, job_id)
    )
    return len(rows) > 0


def get_student_applications(student_id):
    """Get all applications for a student (both JobTrack and external)."""
    return run_query("""
        SELECT a.ApplicationID, a.Status, a.DateApplied, a.LastUpdated,
               a.JobID,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName,
               jp.Deadline,
               a.ExternalSource, a.ExternalURL
        FROM Application a
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        WHERE a.StudentID = %s
        ORDER BY a.DateApplied DESC
    """, (student_id,))


def get_student_app_status_counts(student_id):
    """Get application count grouped by status."""
    return run_query("""
        SELECT Status, COUNT(*) AS cnt
        FROM Application
        WHERE StudentID = %s
        GROUP BY Status
    """, (student_id,))


def add_application(student_id, job_id, date_applied):
    """Insert a new application for a JobTrack-listed job."""
    return run_query(
        "INSERT INTO Application (Status, DateApplied, LastUpdated, StudentID, JobID) VALUES ('Applied', %s, %s, %s, %s)",
        (date_applied, date_applied, student_id, job_id), fetch=False
    )


def add_external_application(student_id, job_title, company_name, source, url, date_applied, status='Applied'):
    """Insert an application for an externally found job (LinkedIn, Indeed, etc.)."""
    run_query(
        """INSERT INTO Application
             (Status, DateApplied, LastUpdated, StudentID,
              ExternalJobTitle, ExternalCompanyName, ExternalSource, ExternalURL)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
        (status, date_applied, date_applied, student_id,
         job_title, company_name, source or None, url or None),
        fetch=False
    )


def update_application_status(app_id, student_id, new_status):
    """Update an application status."""
    run_query(
        "UPDATE Application SET Status=%s, LastUpdated=CURDATE() WHERE ApplicationID=%s AND StudentID=%s",
        (new_status, app_id, student_id), fetch=False
    )


def delete_application(app_id, student_id):
    """Delete an application (student can only delete their own)."""
    run_query(
        "DELETE FROM Application WHERE ApplicationID=%s AND StudentID=%s",
        (app_id, student_id), fetch=False
    )


def get_student_interviews(student_id):
    """Get all interviews for a student (both JobTrack and external apps)."""
    return run_query("""
        SELECT i.InterviewID, i.InterviewDate, i.InterviewType,
               i.MeetingLink, i.FeedbackNotes, i.ApplicationID,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName
        FROM Interview i
        JOIN Application a   ON i.ApplicationID = a.ApplicationID
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        WHERE a.StudentID = %s
        ORDER BY i.InterviewDate ASC
    """, (student_id,))


def add_interview(app_id, date, itype, link, notes):
    """Add an interview record."""
    run_query(
        "INSERT INTO Interview (InterviewDate, InterviewType, MeetingLink, FeedbackNotes, ApplicationID) VALUES (%s,%s,%s,%s,%s)",
        (date, itype, link or None, notes or None, app_id), fetch=False
    )


def update_interview(interview_id, date, itype, link, notes):
    """Update an existing interview."""
    run_query(
        "UPDATE Interview SET InterviewDate=%s, InterviewType=%s, MeetingLink=%s, FeedbackNotes=%s WHERE InterviewID=%s",
        (date, itype, link or None, notes or None, interview_id), fetch=False
    )


def delete_interview(interview_id):
    """Delete an interview record."""
    run_query("DELETE FROM Interview WHERE InterviewID=%s", (interview_id,), fetch=False)


def get_student_advisor_notes(student_id):
    """Get latest advisor notes visible to the student."""
    return run_query("""
        SELECT an.NoteID, an.Note_content, an.DateCreated, an.InterventionFlag,
               CONCAT(adv.firstName, ' ', adv.LastName) AS AdvisorName
        FROM AdvisingNote an
        LEFT JOIN Advisor adv ON an.AdvisorID = adv.AdvisorID
        WHERE an.StudentID = %s
        ORDER BY an.DateCreated DESC
        LIMIT 5
    """, (student_id,))


def get_student_applications_for_dropdown(student_id):
    """Get applications for interview/note dropdowns (JobTrack + external)."""
    return run_query("""
        SELECT a.ApplicationID,
               CONCAT(
                   COALESCE(jp.JobTitle,    a.ExternalJobTitle),
                   ' @ ',
                   COALESCE(jp.CompanyName, a.ExternalCompanyName)
               ) AS Label
        FROM Application a
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        WHERE a.StudentID = %s
        ORDER BY Label
    """, (student_id,))


# ============================================================
# ADVISOR MODULE
# ============================================================

def get_advisor(advisor_id: int) -> dict:
    """Get advisor profile."""
    rows = run_query("SELECT * FROM Advisor WHERE AdvisorID=%s", (advisor_id,))
    return rows[0] if rows else None


def get_advisor_students(advisor_id):
    """Get all students assigned to this advisor with summary stats."""
    return run_query("""
        SELECT s.StudentId,
               s.FirstName, s.LastName, s.Email, s.Major, s.GraduationDate,
               COUNT(DISTINCT a.ApplicationID)                            AS TotalApps,
               SUM(CASE WHEN a.Status='Interview' THEN 1 ELSE 0 END)     AS Interviews,
               SUM(CASE WHEN a.Status='Offer'     THEN 1 ELSE 0 END)     AS Offers,
               SUM(CASE WHEN an.InterventionFlag=1 THEN 1 ELSE 0 END)    AS Flags
        FROM Student s
        LEFT JOIN Application   a  ON s.StudentId  = a.StudentID
        LEFT JOIN AdvisingNote  an ON s.StudentId  = an.StudentID
                                   AND an.AdvisorID = %s
        WHERE s.AdvisorID = %s
        GROUP BY s.StudentId, s.FirstName, s.LastName,
                 s.Email, s.Major, s.GraduationDate
        ORDER BY s.LastName
    """, (advisor_id, advisor_id))


def get_student_apps_for_advisor(student_id):
    """Get all applications for a student (advisor view, includes external)."""
    return run_query("""
        SELECT a.ApplicationID, a.Status, a.DateApplied, a.LastUpdated,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName,
               a.ExternalSource
        FROM Application a
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        WHERE a.StudentID = %s
        ORDER BY a.DateApplied DESC
    """, (student_id,))


def get_advisor_notes(advisor_id):
    """Get all notes written by this advisor, with application context."""
    return run_query("""
        SELECT an.NoteID, an.Note_content, an.DateCreated, an.InterventionFlag,
               CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
               s.StudentId, s.Major, s.Email AS StudentEmail,
               an.ApplicationID,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName
        FROM AdvisingNote an
        JOIN Student s ON an.StudentID = s.StudentId
        LEFT JOIN Application  a  ON an.ApplicationID = a.ApplicationID
        LEFT JOIN Job_Posting  jp ON a.JobID = jp.JobID
        WHERE an.AdvisorID = %s
        ORDER BY an.DateCreated DESC
    """, (advisor_id,))


def get_student_notes_for_advisor(student_id, advisor_id):
    """Get notes per application for a student, written by this advisor."""
    return run_query("""
        SELECT an.NoteID, an.Note_content, an.DateCreated, an.InterventionFlag,
               an.ApplicationID,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName
        FROM AdvisingNote an
        LEFT JOIN Application  a  ON an.ApplicationID = a.ApplicationID
        LEFT JOIN Job_Posting  jp ON a.JobID = jp.JobID
        WHERE an.StudentID = %s AND an.AdvisorID = %s
        ORDER BY an.DateCreated DESC
    """, (student_id, advisor_id))


def get_notes_for_application_advisor(app_id, advisor_id):
    """Get all notes an advisor has written for a specific application."""
    return run_query("""
        SELECT an.NoteID, an.Note_content, an.DateCreated, an.InterventionFlag
        FROM AdvisingNote an
        WHERE an.ApplicationID = %s AND an.AdvisorID = %s
        ORDER BY an.DateCreated DESC
    """, (app_id, advisor_id))


def add_advising_note(advisor_id, student_id, content, flag, app_id=None):
    """Insert a new advising note."""
    run_query("""
        INSERT INTO AdvisingNote
          (Note_content, DateCreated, InterventionFlag, StudentID, ApplicationID, AdvisorID)
        VALUES (%s, CURDATE(), %s, %s, %s, %s)
    """, (content, int(flag), student_id, app_id or None, advisor_id), fetch=False)


def update_advising_note(note_id, content, flag, advisor_id):
    """Update an existing advising note."""
    run_query(
        "UPDATE AdvisingNote SET Note_content=%s, InterventionFlag=%s WHERE NoteID=%s AND AdvisorID=%s",
        (content, int(flag), note_id, advisor_id), fetch=False
    )


def delete_advising_note(note_id, advisor_id):
    """Delete an advising note."""
    run_query(
        "DELETE FROM AdvisingNote WHERE NoteID=%s AND AdvisorID=%s",
        (note_id, advisor_id), fetch=False
    )


def get_intervention_students(advisor_id):
    """Get students with intervention-flagged notes for this advisor."""
    return run_query("""
        SELECT DISTINCT
               s.StudentId, s.FirstName, s.LastName, s.Email, s.Major,
               an.Note_content, an.DateCreated
        FROM AdvisingNote an
        JOIN Student s ON an.StudentID = s.StudentId
        WHERE an.InterventionFlag = TRUE
          AND s.AdvisorID = %s
        ORDER BY an.DateCreated DESC
    """, (advisor_id,))


def get_students_with_no_apps(advisor_id):
    """Get at-risk students with zero applications."""
    return run_query("""
        SELECT s.StudentId, s.FirstName, s.LastName, s.Email, s.Major, s.GraduationDate
        FROM Student s
        LEFT JOIN Application a ON s.StudentId = a.StudentID
        WHERE s.AdvisorID = %s
          AND a.ApplicationID IS NULL
    """, (advisor_id,))


def get_advisor_students_dropdown(advisor_id):
    """Student list for advisor dropdown."""
    return run_query("""
        SELECT StudentId,
               CONCAT(FirstName, ' ', LastName) AS Name,
               Major
        FROM Student
        WHERE AdvisorID = %s
        ORDER BY LastName
    """, (advisor_id,))


def get_advisor_dashboard_stats(advisor_id):
    """Stats for advisor dashboard."""
    stats = {}
    rows = run_query("SELECT COUNT(*) AS cnt FROM Student WHERE AdvisorID=%s", (advisor_id,))
    stats['students'] = rows[0]['cnt'] if rows else 0

    rows = run_query("""
        SELECT COUNT(DISTINCT an.StudentID) AS cnt
        FROM AdvisingNote an
        JOIN Student s ON an.StudentID = s.StudentId
        WHERE an.InterventionFlag=1 AND s.AdvisorID=%s
    """, (advisor_id,))
    stats['interventions'] = rows[0]['cnt'] if rows else 0

    rows = run_query("""
        SELECT COUNT(*) AS cnt FROM AdvisingNote WHERE AdvisorID=%s
    """, (advisor_id,))
    stats['notes'] = rows[0]['cnt'] if rows else 0

    rows = run_query("""
        SELECT COUNT(DISTINCT a.StudentID) AS cnt
        FROM Application a
        JOIN Student s ON a.StudentID = s.StudentId
        WHERE s.AdvisorID=%s AND a.Status='Offer'
    """, (advisor_id,))
    stats['offers'] = rows[0]['cnt'] if rows else 0

    return stats


# ============================================================
# ADMIN MODULE
# ============================================================

def get_admin(admin_id: int) -> dict:
    """Get admin profile."""
    rows = run_query("SELECT * FROM CareerServiceAdmin WHERE AdminID=%s", (admin_id,))
    return rows[0] if rows else None


def get_system_stats() -> dict:
    """System-wide statistics for admin dashboard."""
    stats = {}
    for key, sql in [
        ('students',      "SELECT COUNT(*) AS c FROM Student"),
        ('advisors',      "SELECT COUNT(*) AS c FROM Advisor"),
        ('applications',  "SELECT COUNT(*) AS c FROM Application"),
        ('active_jobs',   "SELECT COUNT(*) AS c FROM Job_Posting WHERE IsActive=1 AND Deadline >= CURDATE()"),
        ('offers',        "SELECT COUNT(*) AS c FROM Application WHERE Status='Offer'"),
        ('interviews',    "SELECT COUNT(*) AS c FROM Application WHERE Status='Interview'"),
        ('interventions', "SELECT COUNT(*) AS c FROM AdvisingNote WHERE InterventionFlag=1"),
        ('total_jobs',    "SELECT COUNT(*) AS c FROM Job_Posting"),
    ]:
        rows = run_query(sql)
        stats[key] = rows[0]['c'] if rows else 0
    return stats


def get_all_job_postings():
    """All employer-submitted job board listings with tracker counts (admin view)."""
    return run_query("""
        SELECT jp.*,
               COUNT(a.ApplicationID) AS Trackers
        FROM Job_Posting jp
        LEFT JOIN Application a ON jp.JobID = a.JobID
        GROUP BY jp.JobID
        ORDER BY jp.Posted DESC
    """)


def create_job_posting(title, description, posted, deadline, company,
                       location, job_type, emp_contact, emp_email, admin_id):
    """Register a new employer-submitted position on the Job Board."""
    return run_query("""
        INSERT INTO Job_Posting
          (JobTitle, Description, Posted, Deadline, CompanyName,
           Location, JobType, EmployerContact, EmployerEmail, IsActive, AdminID)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 1, %s)
    """, (title, description, posted, deadline, company,
          location, job_type, emp_contact or None, emp_email or None, admin_id),
    fetch=False)


def update_job_posting(job_id, title, description, deadline, company,
                       location, job_type, emp_contact, emp_email):
    """Update an existing employer-submitted listing."""
    run_query("""
        UPDATE Job_Posting
        SET JobTitle=%s, Description=%s, Deadline=%s, CompanyName=%s,
            Location=%s, JobType=%s, EmployerContact=%s, EmployerEmail=%s
        WHERE JobID=%s
    """, (title, description, deadline, company,
          location, job_type, emp_contact or None, emp_email or None, job_id),
    fetch=False)


def toggle_job_active(job_id, is_active: bool):
    """Activate or deactivate a job board listing."""
    run_query("UPDATE Job_Posting SET IsActive=%s WHERE JobID=%s",
              (1 if is_active else 0, job_id), fetch=False)


def delete_job_posting(job_id):
    """Remove a listing from the job board."""
    run_query("DELETE FROM Job_Posting WHERE JobID=%s", (job_id,), fetch=False)


def get_application_funnel():
    """Application count by status for funnel chart."""
    return run_query("""
        SELECT Status, COUNT(*) AS cnt
        FROM Application
        GROUP BY Status
        ORDER BY FIELD(Status,'Applied','Interview','Offer','Rejected','Withdrawn')
    """)


def get_company_stats():
    """Application metrics per company (includes external applications)."""
    return run_query("""
        SELECT COALESCE(jp.CompanyName, a.ExternalCompanyName, 'Unknown') AS CompanyName,
               COUNT(a.ApplicationID)                                      AS TotalApps,
               SUM(CASE WHEN a.Status='Interview' THEN 1 ELSE 0 END)      AS Interviews,
               SUM(CASE WHEN a.Status='Offer'     THEN 1 ELSE 0 END)      AS Offers,
               ROUND(
                   SUM(CASE WHEN a.Status='Offer' THEN 1 ELSE 0 END) * 100.0
                   / COUNT(a.ApplicationID), 1
               )                                                            AS OfferRatePct
        FROM Application a
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        GROUP BY COALESCE(jp.CompanyName, a.ExternalCompanyName, 'Unknown')
        ORDER BY TotalApps DESC
    """)


def get_monthly_applications():
    """Monthly application volume."""
    return run_query("""
        SELECT DATE_FORMAT(DateApplied, '%Y-%m') AS Month,
               COUNT(*) AS Applications
        FROM Application
        GROUP BY Month
        ORDER BY Month
    """)


def get_placement_list():
    """Students who received offers (includes external applications)."""
    return run_query("""
        SELECT CONCAT(s.FirstName,' ',s.LastName)              AS StudentName,
               s.Major, s.GraduationDate,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               a.DateApplied
        FROM Application a
        JOIN Student      s  ON a.StudentID = s.StudentId
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        WHERE a.Status = 'Offer'
        ORDER BY CompanyName
    """)


def get_full_student_pipeline():
    """All students with their application pipeline stats (admin view)."""
    return run_query("""
        SELECT s.StudentId,
               CONCAT(s.FirstName,' ',s.LastName)       AS StudentName,
               s.Major, s.GraduationDate,
               COALESCE(CONCAT(adv.firstName,' ',adv.LastName),'Unassigned') AS Advisor,
               COUNT(a.ApplicationID)                   AS TotalApps,
               SUM(CASE WHEN a.Status='Applied'   THEN 1 ELSE 0 END) AS Applied,
               SUM(CASE WHEN a.Status='Interview' THEN 1 ELSE 0 END) AS Interviews,
               SUM(CASE WHEN a.Status='Offer'     THEN 1 ELSE 0 END) AS Offers
        FROM Student s
        LEFT JOIN Advisor     adv ON s.AdvisorID   = adv.AdvisorID
        LEFT JOIN Application a   ON s.StudentId   = a.StudentID
        GROUP BY s.StudentId, StudentName, s.Major, s.GraduationDate, Advisor
        ORDER BY s.LastName
    """)


def get_advisor_effectiveness():
    """Advisor performance metrics for admin reports."""
    return run_query("""
        SELECT CONCAT(adv.firstName,' ',adv.LastName) AS AdvisorName,
               adv.Department,
               COUNT(DISTINCT s.StudentId)            AS Students,
               COUNT(an.NoteID)                       AS TotalNotes,
               SUM(COALESCE(an.InterventionFlag,0))   AS Interventions
        FROM Advisor adv
        LEFT JOIN Student      s  ON s.AdvisorID   = adv.AdvisorID
        LEFT JOIN AdvisingNote an ON an.AdvisorID  = adv.AdvisorID
        GROUP BY adv.AdvisorID, AdvisorName, adv.Department
        ORDER BY Students DESC
    """)


# ============================================================
# REGISTRATION
# ============================================================

def email_exists(email: str) -> bool:
    """Check if email already registered in any role table."""
    for table, col in [('Student', 'StudentId'), ('Advisor', 'AdvisorID'), ('CareerServiceAdmin', 'AdminID')]:
        rows = run_query(f"SELECT {col} FROM {table} WHERE Email=%s", (email,))
        if rows:
            return True
    return False


def get_available_advisors():
    """Return advisors for registration dropdown."""
    return run_query("""
        SELECT AdvisorID,
               CONCAT(firstName, ' ', LastName, ' — ', Department) AS Label
        FROM Advisor
        ORDER BY Department, LastName
    """)


def register_student(first, last, email, password, major, grad_date, advisor_id,
                     security_question=None, security_answer=None):
    """Register a new student account."""
    return run_query(
        """INSERT INTO Student
             (FirstName, LastName, Email, Password, Major, GraduationDate,
              AdvisorID, SecurityQuestion, SecurityAnswer)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (first.strip(), last.strip(), email.strip().lower(),
         password, major.strip(), grad_date, advisor_id or None,
         security_question or None,
         security_answer.strip().lower() if security_answer else None),
        fetch=False
    )


# ── Forgot Password (Security Question) ───────────────────────────────────────

def get_security_question(email: str):
    """
    Look up the security question for an email across all user tables.
    Returns dict with keys: 'question', 'table', 'id_col', 'id_val'
    or None if email not found or no question set.
    """
    checks = [
        ("Student",           "Email", "StudentId"),
        ("Advisor",           "Email", "AdvisorID"),
        ("CareerServiceAdmin","Email", "AdminID"),
    ]
    for table, email_col, id_col in checks:
        rows = run_query(
            f"SELECT {id_col}, SecurityQuestion FROM {table} "
            f"WHERE {email_col}=%s AND SecurityQuestion IS NOT NULL",
            (email.strip().lower(),)
        )
        if rows:
            return {
                'question': rows[0]['SecurityQuestion'],
                'table':    table,
                'id_col':   id_col,
                'id_val':   rows[0][id_col],
            }
    return None


def verify_and_reset_password(email: str, answer: str, new_password: str) -> bool:
    """
    Verify the security answer (case-insensitive) and if correct reset password.
    Returns True on success, False if answer is wrong or email not found.
    """
    checks = [
        ("Student",           "Email", "StudentId"),
        ("Advisor",           "Email", "AdvisorID"),
        ("CareerServiceAdmin","Email", "AdminID"),
    ]
    for table, email_col, id_col in checks:
        rows = run_query(
            f"SELECT {id_col}, SecurityAnswer FROM {table} WHERE {email_col}=%s",
            (email.strip().lower(),)
        )
        if rows:
            stored = (rows[0].get('SecurityAnswer') or '').strip().lower()
            if stored and stored == answer.strip().lower():
                run_query(
                    f"UPDATE {table} SET Password=%s WHERE {email_col}=%s",
                    (new_password, email.strip().lower()), fetch=False
                )
                return True
            return False
    return False


def get_app_advising_notes(app_id: int):
    """Get advisor notes linked to a specific application (student-facing view)."""
    return run_query("""
        SELECT an.NoteID, an.Note_content, an.DateCreated, an.InterventionFlag,
               CONCAT(adv.firstName, ' ', adv.LastName) AS AdvisorName
        FROM AdvisingNote an
        LEFT JOIN Advisor adv ON an.AdvisorID = adv.AdvisorID
        WHERE an.ApplicationID = %s
        ORDER BY an.DateCreated DESC
    """, (app_id,))


# ── Admin User Management ─────────────────────────────────────────────────────

def get_all_students_admin():
    """All students with advisor assignment info."""
    return run_query("""
        SELECT s.StudentId, s.FirstName, s.LastName, s.Email,
               s.Major, s.GraduationDate, s.AdvisorID,
               CONCAT(a.firstName,' ',a.LastName) AS AdvisorName,
               a.Department AS AdvisorDept,
               (SELECT COUNT(*) FROM Application ap WHERE ap.StudentID = s.StudentId) AS AppCount
        FROM Student s
        LEFT JOIN Advisor a ON s.AdvisorID = a.AdvisorID
        ORDER BY s.LastName, s.FirstName
    """)


def get_all_advisors_admin():
    """All advisors with student count."""
    return run_query("""
        SELECT a.AdvisorID, a.firstName, a.LastName, a.Email, a.Department,
               COUNT(s.StudentId) AS StudentCount
        FROM Advisor a
        LEFT JOIN Student s ON s.AdvisorID = a.AdvisorID
        GROUP BY a.AdvisorID, a.firstName, a.LastName, a.Email, a.Department
        ORDER BY a.Department, a.LastName
    """)


def assign_advisor(student_id: int, advisor_id):
    """Assign (or unassign) an advisor to a student."""
    run_query(
        "UPDATE Student SET AdvisorID=%s WHERE StudentId=%s",
        (advisor_id if advisor_id else None, student_id), fetch=False
    )


def delete_student(student_id: int):
    run_query("DELETE FROM Student WHERE StudentId=%s", (student_id,), fetch=False)


def delete_advisor(advisor_id: int):
    run_query("DELETE FROM Advisor WHERE AdvisorID=%s", (advisor_id,), fetch=False)


def add_advisor(first, last, email, password, department):
    run_query(
        "INSERT INTO Advisor (firstName,LastName,Email,Password,Department) VALUES (%s,%s,%s,%s,%s)",
        (first.strip(), last.strip(), email.strip().lower(), password, department.strip()),
        fetch=False
    )


def get_all_applications_admin():
    """Full application list for admin (includes external applications)."""
    return run_query("""
        SELECT a.ApplicationID,
               CONCAT(s.FirstName,' ',s.LastName)              AS StudentName,
               s.Major,
               COALESCE(jp.JobTitle,    a.ExternalJobTitle)    AS JobTitle,
               COALESCE(jp.CompanyName, a.ExternalCompanyName) AS CompanyName,
               COALESCE(a.ExternalSource, 'JobTrack')          AS Source,
               a.Status, a.DateApplied, a.LastUpdated
        FROM Application a
        JOIN Student      s  ON a.StudentID = s.StudentId
        LEFT JOIN Job_Posting jp ON a.JobID = jp.JobID
        ORDER BY a.DateApplied DESC
    """)
