# JobTrack – Setup Guide
## BIS 698 | Group 5 | Central Michigan University

---

## Prerequisites

- Python 3.9 or higher installed
- Connected to **CMU campus Wi-Fi** OR **CMU VPN (GlobalProtect)**
  - VPN download: https://www.cmich.edu/offices-departments/information-technology/services/network-services/vpn
  - ⚠️ App will NOT connect to the database without CMU network / VPN

---

## Step 1 — Install Python Dependencies

Open a terminal / command prompt in the project folder and run:

```bash
pip install -r requirements.txt
```

---

## Step 2 — Database is Already Set Up ✅

The database lives on the **CMU university MySQL server** — no local setup needed.
The `config.py` file already has the correct connection settings:

```python
DB_CONFIG = {
    'host':     '141.209.241.91',
    'user':     'Sp2026BIS698ThuG5',
    'password': 'warm',
    'database': 'Sp2026BIS698ThuG5s',
    'charset':  'utf8mb4',
    'autocommit': True
}
```

> If you need to reload the database from scratch, run `jobtrack_final.sql`
> in MySQL Workbench connected to the university server.

---

## Step 3 — Run the Application

```bash
python -m streamlit run app.py
```

The app will open at: **http://localhost:8501**

---

## Demo Login Credentials

**Password for ALL accounts:** `Password1!`

| Role    | Email                       |
|---------|-----------------------------|
| 🎓 Student | psadanala@cmich.edu      |
| 🎓 Student | hkamatham@cmich.edu      |
| 🎓 Student | pmekala@cmich.edu        |
| 👩‍🏫 Advisor | ltorres@cmich.edu       |
| 👩‍🏫 Advisor | mnguyen@cmich.edu       |
| ⚙️ Admin  | smitchell@cmich.edu      |
| ⚙️ Admin  | jcarter@cmich.edu        |

---

## Project Files

```
BIS_Project_JobTrack/
├── app.py                  Main Streamlit application (all UI + routing)
├── db.py                   Database layer (all MySQL queries)
├── config.py               Database connection settings (edit if needed)
├── jobtrack_final.sql      Full schema + sample data (32 students, 93 apps)
├── requirements.txt        Python package dependencies
└── SETUP.md                This file
```

---

## Features

### 🎓 Student Module
- Dashboard — application metrics, pipeline, advisor notes
- Browse Jobs — search active postings, one-click apply
- My Applications — track JobTrack + external apps (LinkedIn, Indeed, etc.)
- Interviews — log and manage interview schedule
- Profile — edit info and change password

### 👩‍🏫 Advisor Module
- Dashboard — student count, intervention alerts, offer stats
- My Students — view each student's pipeline, add advising notes
- Advising Notes — create / edit / delete notes with intervention flags

### ⚙️ Admin Module
- Dashboard — system-wide KPIs and charts
- Job Postings — full CRUD for employer listings
- Reports — funnel analysis, company metrics, student pipeline, advisor effectiveness
- User Management — assign advisors, manage student/advisor accounts

---

## Technology Stack

| Layer       | Technology                  |
|-------------|-----------------------------|
| Frontend    | Python + Streamlit          |
| Database    | MySQL 8.0 (CMU Server)      |
| Charts      | Plotly Express / Graph Objects |
| Data        | Pandas DataFrames           |
| Fonts       | Google Fonts – Inter        |
