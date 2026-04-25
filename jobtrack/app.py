# ============================================================
# JobTrack - Main Streamlit Application
# BIS 698 - Information Systems Capstone | Group 5
# Central Michigan University
# ============================================================

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import date, datetime
import db

st.set_page_config(
    page_title="JobTrack | CMU Career Services",
    page_icon="🎯",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ============================================================
# CONSTANTS
# ============================================================
STATUSES        = ['Applied', 'Interview', 'Offer', 'Rejected', 'Withdrawn']
INTERVIEW_TYPES = ['Phone Screen', 'Video Call', 'On-site', 'Technical', 'Final Round']
SECURITY_QUESTIONS = [
    'What is the name of your first pet?',
    'What city were you born in?',
    'What was the name of your elementary school?',
    'What is your mother\'s maiden name?',
    'What city did you grow up in?',
]
SOURCES = [
    'LinkedIn', 'Indeed', 'Handshake', 'Company Website',
    'Career Fair', 'Referral', 'CMU Career Services Portal',
    'Job Board (this system)', 'Other'
]
JOB_TYPES = ['Internship', 'Full-time', 'Co-op', 'Part-time']
STATUS_COLORS = {
    'Applied':   '#1976D2', 'Interview': '#7B1FA2',
    'Offer':     '#388E3C', 'Rejected':  '#D32F2F', 'Withdrawn': '#757575',
}
JOB_TYPE_COLORS = {
    'Internship': '#6a0032', 'Full-time':  '#1565c0',
    'Co-op':      '#2e7d32', 'Part-time':  '#e65100',
}
MAJORS = [
    'Business Information Systems', 'Computer Science', 'Finance',
    'Marketing', 'Data Analytics', 'Management', 'Information Systems',
    'Accounting', 'Business Administration', 'Engineering', 'Other'
]


# ============================================================
# CSS — all overrides in one block
# NOTE: We NEVER use st.markdown('<div>') open + close pattern because
# Streamlit renders each call in its own wrapper causing empty boxes.
# HTML cards must be single self-contained st.markdown() calls.
# ============================================================
def inject_css():
    st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');

    /* ══════════════════════════════════════════════════
       GLOBAL
    ══════════════════════════════════════════════════ */
    html, body, .stApp, .main, .block-container,
    [data-testid="stAppViewContainer"],
    [data-testid="stVerticalBlock"],
    [data-testid="stHorizontalBlock"] {
        font-family: 'Inter','Segoe UI',sans-serif !important;
        background-color: #f4f5f7 !important;
        color: #1a1a2e !important;
    }
    .main *, .block-container * { color: #1a1a2e !important; }
    #MainMenu, footer { visibility: hidden !important; }
    /* Hide only the top Streamlit toolbar — NOT the sidebar header (which holds the < > toggle) */
    [data-testid="stHeader"],
    [data-testid="stToolbar"],
    [data-testid="stDecoration"] { visibility: hidden !important; height: 0 !important; }
    /* Sidebar header (contains the collapse < button) — must stay visible */
    [data-testid="stSidebarHeader"] { visibility: visible !important; display: flex !important; }

    /* ══════════════════════════════════════════════════
       SIDEBAR — permanently open, hide all toggle arrows
    ══════════════════════════════════════════════════ */
    [data-testid="stSidebarCollapsedControl"],
    [data-testid="collapsedControl"],
    [data-testid="stSidebarHeader"] button,
    button[data-testid="stSidebarCollapseButton"] {
        display: none !important;
        visibility: hidden !important;
    }
    [data-testid="stSidebarHeader"] {
        background: #6a0032 !important;
        min-height: 0 !important;
        padding: 0 !important;
    }
    /* Sidebar consistent width & alignment */
    [data-testid="stSidebar"] { width: 240px !important; min-width: 240px !important; }
    [data-testid="stSidebar"] > div:first-child { width: 240px !important; }
    [data-testid="stSidebar"] .block-container { padding: 0 !important; }
    [data-testid="stSidebar"] .stButton > button {
        width: 100% !important;
        text-align: left !important;
        display: flex !important;
        align-items: center !important;
    }

    /* ══════════════════════════════════════════════════
       SIDEBAR — Full maroon, every container
    ══════════════════════════════════════════════════ */
    [data-testid="stSidebar"],
    [data-testid="stSidebar"] > div,
    [data-testid="stSidebar"] > div > div,
    [data-testid="stSidebar"] > div > div > div,
    [data-testid="stSidebar"] section,
    [data-testid="stSidebarContent"],
    [data-testid="stSidebar"] [data-testid="stVerticalBlock"],
    [data-testid="stSidebar"] [data-testid="stVerticalBlockBorderWrapper"],
    [data-testid="stSidebar"] .element-container,
    [data-testid="stSidebar"] .block-container,
    [data-testid="stSidebar"] [class*="stBlock"],
    [data-testid="stSidebar"] [class*="css-"] {
        background-color: #6a0032 !important;
        background: #6a0032 !important;
    }
    /* Collapse container gaps */
    [data-testid="stSidebar"] [data-testid="stVerticalBlock"] { gap:0 !important; padding:0 !important; }
    [data-testid="stSidebar"] .element-container,
    [data-testid="stSidebar"] [data-testid="stVerticalBlockBorderWrapper"],
    [data-testid="stSidebar"] .stButton,
    [data-testid="stSidebar"] .stBaseButton {
        margin:0 !important; padding:0 !important;
        border:none !important; box-shadow:none !important; background:#6a0032 !important;
    }
    /* All non-button sidebar text → white */
    [data-testid="stSidebar"] *:not(button):not(input) { color:rgba(255,255,255,0.9) !important; }
    [data-testid="stSidebar"] hr { border-color:rgba(255,255,255,0.12) !important; margin:8px 0 !important; }

    /* NAVIGATION section label */
    [data-testid="stSidebar"] .nav-lbl {
        font-family:'Inter','Segoe UI',sans-serif !important;
        color:rgba(255,255,255,0.32) !important; font-size:9px !important;
        font-weight:700 !important; letter-spacing:2.5px !important;
        text-transform:uppercase !important; padding:12px 20px 4px !important; display:block !important;
    }

    /* ── INACTIVE nav buttons (type="secondary") ─────── */
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"],
    html body [data-testid="stSidebar"] button[kind="secondary"] {
        font-family:'Inter','Segoe UI',sans-serif !important;
        background: rgba(255,255,255,0.0) !important;
        background-color: rgba(255,255,255,0.0) !important;
        border: none !important; border-left: 3px solid transparent !important;
        box-shadow: none !important; outline: none !important;
        color: rgba(255,255,255,0.70) !important;
        font-size: 13.5px !important; font-weight: 400 !important;
        text-align: left !important; width: 100% !important;
        padding: 10px 16px 10px 20px !important;
        border-radius: 0 !important;
        justify-content: flex-start !important;
        line-height: 1.4 !important; min-height: unset !important;
        transition: all 0.15s ease !important;
        display: flex !important; align-items: center !important;
    }
    /* Force all nav button text to a consistent left-aligned column */
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"] p,
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"] span,
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"] div {
        font-family:'Inter','Segoe UI',sans-serif !important;
        background:transparent !important; color:rgba(255,255,255,0.70) !important;
        font-size:13.5px !important; font-weight:400 !important;
        text-align:left !important; white-space: nowrap !important;
        display: block !important; width: 100% !important;
    }
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"]:hover {
        background: rgba(255,255,255,0.08) !important;
        border-left: 3px solid rgba(255,193,7,0.5) !important;
        color: rgba(255,255,255,0.95) !important;
    }
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"]:hover p,
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-secondary"]:hover span {
        color: rgba(255,255,255,0.95) !important; background:transparent !important;
    }

    /* ── ACTIVE nav button (type="primary") ─────────── */
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-primary"],
    html body [data-testid="stSidebar"] button[kind="primary"] {
        font-family:'Inter','Segoe UI',sans-serif !important;
        background: rgba(255,193,7,0.14) !important;
        background-color: rgba(255,193,7,0.14) !important;
        border: none !important; border-left: 3px solid #ffc107 !important;
        box-shadow: none !important; outline: none !important;
        color: #ffd54f !important;
        font-size: 13.5px !important; font-weight: 600 !important;
        text-align: left !important; width: 100% !important;
        padding: 10px 16px 10px 20px !important;
        border-radius: 0 !important;
        justify-content: flex-start !important; display: flex !important;
        align-items: center !important;
        line-height: 1.4 !important; min-height: unset !important;
    }
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-primary"] p,
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-primary"] span,
    html body [data-testid="stSidebar"] [data-testid="stBaseButton-primary"] div {
        font-family:'Inter','Segoe UI',sans-serif !important;
        background:transparent !important; color:#ffd54f !important;
        font-size:13.5px !important; font-weight:600 !important; text-align:left !important;
    }

    /* Sign-out button inherits secondary but slightly different */
    html body [data-testid="stSidebar"] .signout-wrap [data-testid="stBaseButton-secondary"] {
        color: rgba(255,255,255,0.45) !important; font-size:13px !important;
    }
    html body [data-testid="stSidebar"] .signout-wrap [data-testid="stBaseButton-secondary"] p,
    html body [data-testid="stSidebar"] .signout-wrap [data-testid="stBaseButton-secondary"] span {
        color: rgba(255,255,255,0.45) !important;
    }
    html body [data-testid="stSidebar"] .signout-wrap [data-testid="stBaseButton-secondary"]:hover {
        color: #ff8a80 !important; border-left: 3px solid #ff8a80 !important;
        background: rgba(255,100,80,0.08) !important;
    }
    html body [data-testid="stSidebar"] .signout-wrap [data-testid="stBaseButton-secondary"]:hover p,
    html body [data-testid="stSidebar"] .signout-wrap [data-testid="stBaseButton-secondary"]:hover span {
        color: #ff8a80 !important;
    }

    /* ══════════════════════════════════════════════════
       METRIC CARDS (HTML-rendered, colored gradients)
    ══════════════════════════════════════════════════ */
    html body .metric-maroon, html body .metric-maroon * { color:#ffffff !important; }
    html body .metric-green,  html body .metric-green *  { color:#ffffff !important; }
    html body .metric-blue,   html body .metric-blue *   { color:#ffffff !important; }
    html body .metric-gold,   html body .metric-gold *   { color:#1a0a00 !important; }
    html body .metric-plain,  html body .metric-plain *  { color:#1a1a2e !important; }
    .metric-maroon { background:linear-gradient(135deg,#6a0032 0%,#a0004f 100%) !important; border-radius:12px; padding:20px 22px; }
    .metric-gold   { background:linear-gradient(135deg,#c97a00 0%,#ffc107 100%) !important; border-radius:12px; padding:20px 22px; }
    .metric-green  { background:linear-gradient(135deg,#145214 0%,#2e7d32 100%) !important; border-radius:12px; padding:20px 22px; }
    .metric-blue   { background:linear-gradient(135deg,#0a3472 0%,#1565c0 100%) !important; border-radius:12px; padding:20px 22px; }
    .metric-plain  { background:#ffffff !important; border:1px solid #e8e8e8; border-radius:12px; padding:20px 22px; box-shadow:0 1px 4px rgba(0,0,0,0.06); }
    .mlabel { font-size:12px !important; font-weight:600 !important; opacity:0.75; letter-spacing:0.3px; text-transform:uppercase; }
    .mvalue { font-size:2.2rem !important; font-weight:800 !important; line-height:1.05; margin-top:6px; letter-spacing:-1px; }
    .mdelta { font-size:11.5px !important; font-weight:500 !important; margin-top:5px; opacity:0.70; }

    /* Streamlit native metric */
    [data-testid="metric-container"] {
        background:#ffffff !important; border:1px solid #e8e8e8 !important;
        border-radius:12px !important; padding:20px 22px !important;
        box-shadow:0 1px 4px rgba(0,0,0,0.05) !important;
    }
    [data-testid="stMetricLabel"] * { color:#6b6b7b !important; font-size:12px !important; font-weight:600 !important; text-transform:uppercase; letter-spacing:0.3px; }
    [data-testid="stMetricValue"] * { color:#1a1a2e !important; font-size:2rem !important; font-weight:800 !important; }

    /* ══════════════════════════════════════════════════
       FORM ELEMENTS
    ══════════════════════════════════════════════════ */
    .stTextInput > label, .stTextArea > label, .stSelectbox > label,
    .stDateInput > label, .stCheckbox > label, .stNumberInput > label,
    .stMultiSelect > label {
        color:#1a1a2e !important; font-weight:600 !important;
        font-size:13px !important; letter-spacing:0.1px !important;
    }
    .stTextInput input, .stNumberInput input {
        color:#1a1a2e !important; background:#ffffff !important;
        border:1.5px solid #d8dce4 !important; border-radius:8px !important;
        font-size:14px !important; padding:10px 14px !important;
        transition:border-color 0.15s !important;
    }
    .stTextArea textarea {
        color:#1a1a2e !important; background:#ffffff !important;
        border:1.5px solid #d8dce4 !important; border-radius:8px !important; font-size:14px !important;
    }
    .stTextInput input:focus, .stTextArea textarea:focus,
    .stNumberInput input:focus { border-color:#6a0032 !important; box-shadow:0 0 0 3px rgba(106,0,50,0.08) !important; }
    .stSelectbox [data-baseweb="select"] > div {
        background:#ffffff !important; color:#1a1a2e !important;
        border:1.5px solid #d8dce4 !important; border-radius:8px !important;
    }
    .stSelectbox [data-baseweb="select"] span { color:#1a1a2e !important; }
    .stDateInput input {
        color:#1a1a2e !important; background:#ffffff !important;
        border:1.5px solid #d8dce4 !important; border-radius:8px !important;
    }
    .stCheckbox span, .stCheckbox label span { color:#1a1a2e !important; font-size:14px !important; }

    /* ══════════════════════════════════════════════════
       PASSWORD VISIBILITY TOGGLE — keep it clean/light
       NOTE: placed AFTER main-button rules so specificity wins
    ══════════════════════════════════════════════════ */

    /* ══════════════════════════════════════════════════
       MAIN CONTENT BUTTONS
    ══════════════════════════════════════════════════ */
    /* Classic selector (.stButton) + modern data-testid selector for newer Streamlit */
    .main .stButton > button,
    .block-container .stButton > button,
    .main button[data-testid="stBaseButton-secondary"],
    .block-container button[data-testid="stBaseButton-secondary"],
    .main button[data-testid="stBaseButton-primary"],
    .block-container button[data-testid="stBaseButton-primary"] {
        background:#6a0032 !important; color:#ffffff !important;
        border:none !important; border-radius:8px !important;
        font-weight:600 !important; font-size:13.5px !important;
        padding:9px 22px !important; letter-spacing:0.1px !important;
        transition:background 0.15s, box-shadow 0.15s !important;
        box-shadow:0 2px 6px rgba(106,0,50,0.25) !important;
    }
    .main .stButton > button:hover,
    .block-container .stButton > button:hover,
    .main button[data-testid="stBaseButton-secondary"]:hover,
    .block-container button[data-testid="stBaseButton-secondary"]:hover,
    .main button[data-testid="stBaseButton-primary"]:hover,
    .block-container button[data-testid="stBaseButton-primary"]:hover {
        background:#8b0040 !important; box-shadow:0 4px 12px rgba(106,0,50,0.35) !important;
    }
    .main .stButton > button *,
    .block-container .stButton > button *,
    .main button[data-testid="stBaseButton-secondary"] *,
    .block-container button[data-testid="stBaseButton-secondary"] *,
    .main button[data-testid="stBaseButton-primary"] *,
    .block-container button[data-testid="stBaseButton-primary"] * { color:#ffffff !important; }

    /* ══════════════════════════════════════════════════
       PASSWORD EYE TOGGLE — MUST come AFTER main button rules
       Use multi-selector to beat specificity of .block-container rules
    ══════════════════════════════════════════════════ */
    [data-baseweb="input"] button,
    [data-baseweb="input"] [data-testid="stBaseButton-secondary"],
    [data-testid="stPasswordInputVisibilityButton"],
    .stTextInput button,
    .stTextInput [data-testid="stBaseButton-secondary"],
    [data-testid="stTextInput"] button {
        background: transparent !important;
        background-color: transparent !important;
        border: none !important;
        box-shadow: none !important;
        color: #6b6b7b !important;
        padding: 4px 8px !important;
        min-height: unset !important;
        width: auto !important;
    }
    [data-baseweb="input"] button svg,
    [data-testid="stPasswordInputVisibilityButton"] svg,
    .stTextInput button svg { fill: #6b6b7b !important; color: #6b6b7b !important; }

    /* Form submit buttons (Sign In uses st.form_submit_button) */
    .stFormSubmitButton > button,
    button[data-testid="stBaseButton-secondaryFormSubmit"],
    button[data-testid="stFormSubmitButton"] {
        background:#6a0032 !important; color:#fff !important;
        border-radius:8px !important; font-weight:700 !important;
        font-size:14px !important; border:none !important; padding:10px 26px !important;
        box-shadow:0 2px 8px rgba(106,0,50,0.30) !important;
        width: 100% !important;
    }
    .stFormSubmitButton > button *,
    button[data-testid="stBaseButton-secondaryFormSubmit"] * { color:#fff !important; }
    .stFormSubmitButton > button:hover,
    button[data-testid="stBaseButton-secondaryFormSubmit"]:hover { background:#8b0040 !important; }

    /* ══════════════════════════════════════════════════
       TABS
    ══════════════════════════════════════════════════ */
    .stTabs [data-baseweb="tab-list"] {
        background:transparent !important; border-bottom:2px solid #e4e6eb !important; gap:2px !important;
    }
    .stTabs [data-baseweb="tab"] {
        color:#6b6b7b !important; background:transparent !important;
        font-weight:500 !important; font-size:14px !important;
        padding:10px 20px !important; border-bottom:2px solid transparent !important; margin-bottom:-2px !important;
    }
    .stTabs [data-baseweb="tab"]:hover { color:#6a0032 !important; }
    .stTabs [aria-selected="true"] { color:#6a0032 !important; font-weight:700 !important; border-bottom:2px solid #6a0032 !important; }
    .stTabs [data-baseweb="tab-panel"] { background:transparent !important; padding-top:18px !important; }

    /* ══════════════════════════════════════════════════
       EXPANDERS / DATAFRAME / ALERTS / HEADINGS
    ══════════════════════════════════════════════════ */
    .stExpander { background:#fff !important; border:1px solid #e4e6eb !important; border-radius:10px !important; margin-bottom:10px !important; }
    details > summary { color:#1a1a2e !important; font-weight:600 !important; font-size:14px !important; background:#f8f9fb !important; padding:13px 18px !important; border-radius:10px !important; }
    [data-testid="stDataFrame"] { background:#fff !important; border-radius:10px !important; border:1px solid #e4e6eb !important; overflow:hidden !important; }
    [data-testid="stDataFrame"] th { background:#6a0032 !important; color:#fff !important; font-weight:700 !important; font-size:12.5px !important; letter-spacing:0.2px; }
    [data-testid="stDataFrame"] td { color:#1a1a2e !important; font-size:13px !important; }
    [data-testid="stDataFrame"] tr:nth-child(even) td { background:#fafbfc !important; }
    .stAlert { border-radius:10px !important; }
    .stAlert * { color:inherit !important; font-size:14px !important; }
    h1,h2,h3,h4,h5,h6,[data-testid="stHeading"] { color:#1a1a2e !important; font-weight:700 !important; }
    [data-testid="stCaptionContainer"] * { color:#6b6b7b !important; font-size:13px !important; }
    .stMarkdown strong { font-weight:700 !important; }

    /* ══════════════════════════════════════════════════
       CUSTOM HTML COMPONENTS
    ══════════════════════════════════════════════════ */
    /* Cards */
    .jt-card {
        background:#ffffff; border:1px solid #e4e6eb; border-radius:12px;
        padding:20px 22px; margin-bottom:16px;
        box-shadow:0 1px 6px rgba(0,0,0,0.05);
    }
    html body .jt-card * { color:#1a1a2e !important; }
    .jt-card-title {
        font-size:14.5px; font-weight:700; color:#1a1a2e !important;
        margin-bottom:14px; padding-bottom:10px;
        border-bottom:1px solid #f0f1f3;
        display:flex; align-items:center; gap:6px;
    }

    /* Page header */
    .jt-ph { padding:4px 0 18px; border-bottom:2px solid #e4e6eb; margin-bottom:24px; }
    .jt-title { font-size:26px; font-weight:800; color:#6a0032 !important; line-height:1.2; margin:0; letter-spacing:-0.5px; }
    .jt-sub { font-size:14px; color:#6b6b7b !important; margin-top:5px; font-weight:400; }

    /* Status badges */
    .jt-badge { display:inline-flex; align-items:center; padding:3px 10px; border-radius:20px; font-size:11.5px; font-weight:600; letter-spacing:0.2px; }
    .b-applied   { background:#e8f0fe !important; color:#1a56b0 !important; }
    .b-interview { background:#f0e6ff !important; color:#6d28d9 !important; }
    .b-offer     { background:#d1fae5 !important; color:#065f46 !important; }
    .b-rejected  { background:#fee2e2 !important; color:#991b1b !important; }
    .b-withdrawn { background:#f3f4f6 !important; color:#4b5563 !important; }
    html body .b-applied *   { color:#1a56b0 !important; }
    html body .b-interview * { color:#6d28d9 !important; }
    html body .b-offer *     { color:#065f46 !important; }
    html body .b-rejected *  { color:#991b1b !important; }
    html body .b-withdrawn * { color:#4b5563 !important; }

    /* App/job row cards */
    .app-card {
        background:#ffffff; border:1px solid #e4e6eb; border-radius:10px;
        padding:14px 18px; margin-bottom:8px;
        transition:box-shadow 0.15s, border-color 0.15s;
    }
    .app-card:hover { box-shadow:0 4px 12px rgba(0,0,0,0.08); border-color:#c8cdd6; }
    html body .app-card * { color:#1a1a2e !important; }
    .app-title { font-size:14.5px; font-weight:700; color:#1a1a2e !important; }
    .app-sub { font-size:12.5px; color:#6b6b7b !important; margin-top:3px; }
    html body .app-title { color:#1a1a2e !important; }
    html body .app-sub   { color:#6b6b7b !important; }

    /* Advising note cards */
    .note-card {
        border-left:3px solid #6a0032; background:#fafbfc;
        border-radius:0 10px 10px 0; padding:12px 16px;
        margin-bottom:8px; border-top:1px solid #f0f1f3; border-right:1px solid #f0f1f3; border-bottom:1px solid #f0f1f3;
    }
    html body .note-card * { color:#1a1a2e !important; }
    .note-flag { border-left:3px solid #ffc107 !important; background:#fffbf0 !important; }

    /* Info banners */
    .jt-info { background:#fffbeb; border-left:3px solid #ffc107; padding:12px 16px; border-radius:6px; margin-bottom:16px; }
    .jt-admin-info { background:#fdf2f8; border-left:3px solid #6a0032; padding:12px 16px; border-radius:6px; margin-bottom:16px; }
    html body .jt-info * { color:#78350f !important; }
    html body .jt-admin-info * { color:#4a0028 !important; }

    /* Scrollbar */
    ::-webkit-scrollbar { width:5px; height:5px; }
    ::-webkit-scrollbar-track { background:#f4f5f7; }
    ::-webkit-scrollbar-thumb { background:#c0c4cc; border-radius:3px; }
    ::-webkit-scrollbar-thumb:hover { background:#6a0032; }
    </style>
    """, unsafe_allow_html=True)


# ============================================================
# SESSION STATE
# ============================================================
def init_session():
    for key, default in [
        ('user',None),('role',None),('user_id',None),
        ('page','dashboard'),('show_register',False),
        ('selected_student',None),
    ]:
        if key not in st.session_state:
            st.session_state[key] = default


def logout():
    for k in list(st.session_state.keys()):
        del st.session_state[k]
    st.rerun()


def nav_to(page):
    st.session_state.page = page
    st.rerun()


# ============================================================
# UTILITY
# ============================================================
STATUS_BADGE = {
    'Applied':   '<span class="jt-badge b-applied">Applied</span>',
    'Interview': '<span class="jt-badge b-interview">Interview</span>',
    'Offer':     '<span class="jt-badge b-offer">Offer</span>',
    'Rejected':  '<span class="jt-badge b-rejected">Rejected</span>',
    'Withdrawn': '<span class="jt-badge b-withdrawn">Withdrawn</span>',
}


def fmt_date(d):
    if d is None: return '—'
    if isinstance(d, (date, datetime)): return d.strftime('%b %d, %Y')
    return str(d)


def page_header(title, subtitle=''):
    st.markdown(f"""
    <div class="jt-ph">
        <div class="jt-title">{title}</div>
        {'<div class="jt-sub">' + subtitle + '</div>' if subtitle else ''}
    </div>
    """, unsafe_allow_html=True)


def metric_card(label, value, color='plain', delta=''):
    delta_html = f'<div class="mdelta">{delta}</div>' if delta else ''
    st.markdown(f"""
    <div class="metric-{color}">
        <div class="mlabel">{label}</div>
        <div class="mvalue">{value}</div>
        {delta_html}
    </div>
    """, unsafe_allow_html=True)


def career_link(emp_email, company_name):
    """Generate a best-effort careers page link from employer email domain."""
    if emp_email and '@' in emp_email:
        domain = emp_email.split('@')[-1]
        return f"https://www.{domain}/careers"
    company_slug = company_name.lower().replace(' ', '').replace('&', '').replace(',', '')
    return f"https://www.{company_slug}.com/careers"


# ============================================================
# LOGIN PAGE
# ============================================================
def show_forgot_password():
    """3-step forgot password flow using security questions."""
    st.markdown('<style>[data-testid="stSidebar"]{display:none!important;}</style>',
                unsafe_allow_html=True)

    _, col, _ = st.columns([1, 1.1, 1])
    with col:
        st.markdown("""
        <div style="text-align:center;margin:40px 0 28px;">
            <div style="font-size:42px;font-weight:800;color:#6a0032;letter-spacing:0.5px;line-height:1;">
                Job<span style="color:#ffc107;">Track</span>
            </div>
            <div style="font-size:13px;color:#9b9b9b;margin-top:8px;">Reset Your Password</div>
        </div>
        """, unsafe_allow_html=True)

        step = st.session_state.get('fp_step', 'email')

        with st.container(border=True):

            # ── STEP 1: Enter email ──────────────────────────────
            if step == 'email':
                st.markdown("### 🔑 Forgot Password")
                st.caption("Enter your CMU email address and we'll ask your security question.")
                st.markdown("")
                fp_email = st.text_input("CMU Email Address", placeholder="smith1js@cmich.edu",
                                         key="fp_email_input")
                st.markdown("")
                if st.button("Continue  →", use_container_width=True, key="fp_continue"):
                    if not fp_email.strip():
                        st.error("Please enter your email address.")
                    else:
                        result = db.get_security_question(fp_email.strip().lower())
                        if result:
                            st.session_state.fp_email    = fp_email.strip().lower()
                            st.session_state.fp_question = result['question']
                            st.session_state.fp_step     = 'question'
                            st.rerun()
                        else:
                            st.error("❌ Email not found or no security question set. Contact Career Services IT.")

            # ── STEP 2: Answer security question ────────────────
            elif step == 'question':
                st.markdown("### 🔐 Security Question")
                st.caption(f"Answering for: **{st.session_state.fp_email}**")
                st.markdown("")
                st.info(f"**{st.session_state.fp_question}**")
                fp_answer = st.text_input("Your Answer", placeholder="Type your answer (not case-sensitive)",
                                          key="fp_answer_input")
                st.markdown("")
                if st.button("Verify Answer  →", use_container_width=True, key="fp_verify"):
                    if not fp_answer.strip():
                        st.error("Please enter your answer.")
                    else:
                        # Peek at stored answer to verify without resetting password yet
                        checks = [("Student","Email","StudentId"),
                                  ("Advisor","Email","AdvisorID"),
                                  ("CareerServiceAdmin","Email","AdminID")]
                        verified = False
                        for tbl, ecol, idcol in checks:
                            rows = db.run_query(
                                f"SELECT SecurityAnswer FROM {tbl} WHERE {ecol}=%s",
                                (st.session_state.fp_email,))
                            if rows:
                                stored = (rows[0].get('SecurityAnswer') or '').strip().lower()
                                if stored and stored == fp_answer.strip().lower():
                                    verified = True
                                break
                        if verified:
                            st.session_state.fp_answer = fp_answer.strip()
                            st.session_state.fp_step   = 'reset'
                            st.rerun()
                        else:
                            st.error("❌ Incorrect answer. Please try again.")

            # ── STEP 3: Set new password ─────────────────────────
            elif step == 'reset':
                st.markdown("### ✅ Set New Password")
                st.caption(f"Setting new password for: **{st.session_state.fp_email}**")
                st.markdown("")
                new_pw  = st.text_input("New Password", type="password",
                                        placeholder="Min. 8 characters", key="fp_new_pw")
                conf_pw = st.text_input("Confirm Password", type="password",
                                        placeholder="Re-enter new password", key="fp_conf_pw")
                st.markdown("")
                if st.button("Reset Password  →", use_container_width=True, key="fp_reset"):
                    if not new_pw or not conf_pw:
                        st.error("Please fill in both fields.")
                    elif len(new_pw) < 8:
                        st.error("Password must be at least 8 characters.")
                    elif new_pw != conf_pw:
                        st.error("Passwords do not match.")
                    else:
                        ok = db.verify_and_reset_password(
                            st.session_state.fp_email,
                            st.session_state.fp_answer,
                            new_pw
                        )
                        if ok:
                            st.success("✅ Password reset successfully! You can now sign in.")
                            for k in ['fp_step','fp_email','fp_question','fp_answer']:
                                st.session_state.pop(k, None)
                            st.session_state.show_forgot = False
                            st.rerun()
                        else:
                            st.error("Reset failed. Please start over.")

        st.markdown('<hr style="border:none;border-top:1px solid #eee;margin:16px 0;">', unsafe_allow_html=True)
        if st.button("←  Back to Sign In", use_container_width=True, key="fp_back"):
            for k in ['fp_step','fp_email','fp_question','fp_answer']:
                st.session_state.pop(k, None)
            st.session_state.show_forgot = False
            st.rerun()


def show_login():
    st.markdown("""
    <style>
    [data-testid="stSidebar"] { display:none !important; }
    </style>
    """, unsafe_allow_html=True)

    _, col, _ = st.columns([1, 1.1, 1])
    with col:
        # Logo
        st.markdown("""
        <div style="text-align:center;margin:40px 0 28px;">
            <div style="font-size:42px;font-weight:800;color:#6a0032;letter-spacing:0.5px;line-height:1;">
                Job<span style="color:#ffc107;">Track</span>
            </div>
            <div style="font-size:13px;color:#9b9b9b;margin-top:8px;">
                Central Michigan University &nbsp;·&nbsp; Career Services
            </div>
        </div>
        """, unsafe_allow_html=True)

        # ── detect forgot-password trigger via query param (clean HTML link approach)
        if st.query_params.get("forgot") == "1":
            st.query_params.clear()
            st.session_state.show_forgot = True
            st.rerun()

        # Remove form border
        st.markdown("""
        <style>
        [data-testid="stForm"] { border:none !important; padding:0 !important; background:transparent !important; }
        </style>
        """, unsafe_allow_html=True)

        # Card
        with st.container(border=True):
            st.markdown("### Welcome back!")
            st.caption("Sign in with your CMU credentials. Students, advisors, and admins use the same login.")
            st.markdown("")

            # Login form
            with st.form("login_form", clear_on_submit=False):
                email    = st.text_input("CMU Email Address", placeholder="smith1js@cmich.edu", key="login_email")
                password = st.text_input("Password", type="password", placeholder="••••••••", key="login_pw")

                # "Forgot password?" as a clean right-aligned HTML link (query param trigger)
                st.markdown("""
                <div style="text-align:right; margin:4px 0 14px 0;">
                    <a href="?forgot=1" target="_self"
                       style="color:#6a0032;font-size:13px;font-weight:500;
                              text-decoration:none;border-bottom:1px solid #6a0032;
                              padding-bottom:1px;cursor:pointer;">
                        Forgot password?
                    </a>
                </div>
                """, unsafe_allow_html=True)

                signin_clicked = st.form_submit_button("Sign In  →", use_container_width=True)

            if signin_clicked:
                if not email or not password:
                    st.error("Please enter your email and password.")
                else:
                    result = db.authenticate(email.strip().lower(), password)
                    if result:
                        role, uid, name = result
                        st.session_state.user    = name
                        st.session_state.role    = role
                        st.session_state.user_id = uid
                        st.session_state.page    = 'dashboard'
                        st.rerun()
                    else:
                        st.error("❌ Invalid email or password. Please try again.")

            st.markdown('<hr style="border:none;border-top:1px solid #eee;margin:16px 0;">', unsafe_allow_html=True)
            st.markdown('<p style="text-align:center;font-size:13px;color:#888;margin:0 0 10px;">New student? Create a free account.</p>', unsafe_allow_html=True)

            if st.button("📝  Create Student Account", use_container_width=True, key="go_register"):
                st.session_state.show_register = True
                st.rerun()

        with st.expander("👁️  Demo credentials (password: Password1!)"):
            st.markdown("""
| Role | Email |
|------|-------|
| 🎓 Student | psadanala@cmich.edu |
| 👩‍🏫 Advisor | ltorres@cmich.edu |
| ⚙️ Admin | smitchell@cmich.edu |
            """)

        st.markdown('<p style="text-align:center;font-size:11px;color:#ccc;margin-top:16px;">© 2026 Central Michigan University · Career Services · JobTrack v1.0</p>', unsafe_allow_html=True)


# ============================================================
# REGISTRATION PAGE
# ============================================================
def show_register():
    st.markdown("""
    <style>[data-testid="stSidebar"] { display:none !important; }</style>
    """, unsafe_allow_html=True)

    _, col, _ = st.columns([1, 1.3, 1])
    with col:
        st.markdown("""
        <div style="text-align:center;margin:32px 0 24px;">
            <div style="font-size:38px;font-weight:800;color:#6a0032;line-height:1;">
                Job<span style="color:#ffc107;">Track</span>
            </div>
            <div style="font-size:13px;color:#9b9b9b;margin-top:6px;">Create your student account</div>
        </div>
        """, unsafe_allow_html=True)

        with st.container(border=True):
            st.markdown("### Student Registration")
            st.caption("Fill in your details below. Only students self-register. Advisors and admins are provisioned by Career Services IT. Your advisor will be assigned by the Career Services team.")
            st.markdown("")

            with st.form("register_form"):
                c1, c2 = st.columns(2)
                with c1:
                    reg_first = st.text_input("First Name *", placeholder="Jordan")
                    reg_email = st.text_input("CMU Email *", placeholder="smith1js@cmich.edu")
                    reg_pw    = st.text_input("Password *", type="password", placeholder="Min. 8 characters")
                with c2:
                    reg_last  = st.text_input("Last Name *", placeholder="Smith")
                    reg_major = st.selectbox("Program / Major *", ["-- Select --"] + MAJORS)
                    reg_cpw   = st.text_input("Confirm Password *", type="password", placeholder="Re-enter password")

                reg_grad = st.text_input("Expected Graduation (e.g. May 2026)", placeholder="May 2026")

                st.markdown('<hr style="border:none;border-top:1px solid #eee;margin:8px 0 4px;">', unsafe_allow_html=True)
                st.markdown("**🔑 Security Question** — used to recover your password if forgotten")
                reg_sq = st.selectbox("Select a security question *", ["-- Select --"] + SECURITY_QUESTIONS)
                reg_sa = st.text_input("Your Answer *", placeholder="Answer (not case-sensitive)")
                st.caption("💡 An advisor will be assigned to you by Career Services after registration.")

                submitted = st.form_submit_button("Create Account  →", use_container_width=True)
                if submitted:
                    errors = []
                    if not reg_first.strip(): errors.append("First name is required.")
                    if not reg_last.strip():  errors.append("Last name is required.")
                    if not reg_email.strip(): errors.append("Email is required.")
                    elif '@cmich.edu' not in reg_email.lower():
                        errors.append("Must use a valid @cmich.edu email address.")
                    if reg_major == "-- Select --": errors.append("Please select your program/major.")
                    if not reg_pw: errors.append("Password is required.")
                    elif len(reg_pw) < 8: errors.append("Password must be at least 8 characters.")
                    elif reg_pw != reg_cpw: errors.append("Passwords do not match.")
                    if reg_sq == "-- Select --": errors.append("Please select a security question.")
                    if not reg_sa.strip(): errors.append("Security answer is required.")

                    if not errors and db.email_exists(reg_email.strip().lower()):
                        errors.append("This email is already registered. Please sign in.")

                    if errors:
                        for e in errors:
                            st.error(e)
                    else:
                        new_id = db.register_student(
                            reg_first, reg_last, reg_email, reg_pw,
                            reg_major, reg_grad or None, None,
                            reg_sq, reg_sa   # security question & answer
                        )
                        if new_id:
                            st.success(f"✅ Account created! Welcome, {reg_first}! You can now sign in.")
                            st.balloons()
                            st.session_state.show_register = False
                            st.rerun()
                        else:
                            st.error("Registration failed. Please try again.")

            st.markdown('<hr style="border:none;border-top:1px solid #eee;margin:14px 0;">', unsafe_allow_html=True)
            if st.button("←  Back to Sign In", use_container_width=True, key="back_login"):
                st.session_state.show_register = False
                st.rerun()

        st.markdown('<p style="text-align:center;font-size:11px;color:#ccc;margin-top:14px;">© 2026 Central Michigan University · Career Services</p>', unsafe_allow_html=True)


# ============================================================
# SIDEBAR
# ============================================================
def sidebar_header():
    name  = st.session_state.user or ''
    role  = st.session_state.role or ''
    initials  = ''.join(w[0].upper() for w in name.split()[:2]) if name else 'U'
    role_icon = {'student':'🎓','advisor':'👩‍🏫','admin':'⚙️'}.get(role,'')
    role_label = {'student':'Student','advisor':'Advisor','admin':'Admin'}.get(role,'')
    st.sidebar.markdown(f"""
    <div style="padding:22px 20px 16px;">
        <div style="font-size:22px;font-weight:800;letter-spacing:-0.8px;
                    font-family:'Inter','Segoe UI',sans-serif;color:#fff;line-height:1;margin-bottom:3px;">
            Job<span style="color:#ffc107;">Track</span>
        </div>
        <div style="font-size:10.5px;color:rgba(255,255,255,0.38);letter-spacing:0.8px;text-transform:uppercase;font-weight:500;">
            CMU Career Services
        </div>
    </div>
    <div style="margin:0 12px 8px;background:rgba(255,255,255,0.08);
                border-radius:10px;padding:12px 14px;display:flex;align-items:center;gap:12px;">
        <div style="width:40px;height:40px;background:linear-gradient(135deg,#ffc107,#e6a800);
                    border-radius:50%;display:flex;align-items:center;justify-content:center;
                    font-weight:800;color:#6a0032;font-size:15px;flex-shrink:0;">{initials}</div>
        <div style="min-width:0;flex:1;">
            <div style="font-size:13.5px;font-weight:700;color:#fff;
                        white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.2;">{name}</div>
            <div style="font-size:11px;color:rgba(255,255,255,0.45);margin-top:2px;">
                {role_icon} {role_label}
            </div>
        </div>
    </div>
    """, unsafe_allow_html=True)


# ============================================================
# ══════════════  STUDENT  ══════════════
# ============================================================

def _nav_button(label, key, target, current_page):
    """Nav button: type='primary' when active (gets gold CSS), 'secondary' when inactive."""
    is_active = current_page == target
    if st.sidebar.button(label, key=key, use_container_width=True,
                         type="primary" if is_active else "secondary"):
        nav_to(target)


def student_sidebar():
    sidebar_header()
    cur = st.session_state.page
    st.sidebar.markdown('<span class="nav-lbl">Navigation</span>', unsafe_allow_html=True)
    _nav_button("🏠  Dashboard",        "snav_dash",  "dashboard",    cur)
    _nav_button("📌  Job Board",        "snav_jobs",  "jobs",         cur)
    _nav_button("📋  My Applications",  "snav_apps",  "applications", cur)
    _nav_button("🗓️  Interviews",       "snav_ivw",   "interviews",   cur)
    _nav_button("👤  My Profile",       "snav_prof",  "profile",      cur)
    st.sidebar.markdown('<div style="height:14px;"></div>', unsafe_allow_html=True)
    if st.sidebar.button("↩  Sign Out", key="s_out", use_container_width=True, type="secondary"):
        logout()


def student_dashboard():
    sid     = st.session_state.user_id
    student = db.get_student(sid)
    if not student:
        st.error("Student record not found."); return

    page_header(f"👋 Welcome back, {student['FirstName']}!",
                f"{student['Major']} · Class of {student['GraduationDate']}")

    apps          = db.get_student_applications(sid)
    status_counts = {r['Status']: r['cnt'] for r in db.get_student_app_status_counts(sid)}
    interviews    = db.get_student_interviews(sid)
    active_jobs   = db.get_active_jobs()

    # ── Interview Reminder Alerts ──────────────────────────────
    if interviews:
        upcoming_7 = sorted(
            [i for i in interviews if 0 <= (i['InterviewDate'] - date.today()).days <= 7],
            key=lambda x: x['InterviewDate']
        )
        if upcoming_7:
            for iv in upcoming_7:
                days = (iv['InterviewDate'] - date.today()).days
                if days == 0:
                    bg, border, icon, urgency = '#fff3cd', '#e65100', '🔴', 'TODAY'
                elif days == 1:
                    bg, border, icon, urgency = '#fff3cd', '#f57c00', '🟠', 'TOMORROW'
                elif days <= 3:
                    bg, border, icon, urgency = '#fff8e1', '#ffc107', '🟡', f'in {days} days'
                else:
                    bg, border, icon, urgency = '#e8f5e9', '#388e3c', '🟢', f'in {days} days'
                st.markdown(f"""
                <div style="background:{bg};border-left:4px solid {border};border-radius:8px;
                            padding:12px 16px;margin-bottom:8px;display:flex;align-items:center;gap:12px;">
                    <div style="font-size:22px;">{icon}</div>
                    <div style="flex:1;">
                        <div style="font-weight:700;font-size:14px;color:#1a1a2e;">
                            Interview Reminder &nbsp;·&nbsp;
                            <span style="color:{border};">{urgency.upper()}</span>
                        </div>
                        <div style="font-size:13px;color:#495057;margin-top:2px;">
                            <b>{iv['JobTitle']}</b> at <b>{iv['CompanyName']}</b>
                            &nbsp;·&nbsp; {iv['InterviewType']}
                            &nbsp;·&nbsp; 📅 {iv['InterviewDate'].strftime('%A, %b %d %Y')}
                        </div>
                    </div>
                </div>
                """, unsafe_allow_html=True)

    c1,c2,c3,c4 = st.columns(4)
    with c1: metric_card("📝 Total Applications", len(apps), "maroon")
    with c2: metric_card("🗓️ Interviews", status_counts.get('Interview',0), "gold")
    with c3: metric_card("🎉 Offers Received", status_counts.get('Offer',0), "green")
    with c4: metric_card("💼 Open Positions", len(active_jobs), "blue")
    st.markdown("<br>", unsafe_allow_html=True)

    col_l, col_r = st.columns([2,1])

    with col_l:
        # Pipeline card — all HTML in one call, no widgets
        pipeline_data = {s: status_counts.get(s,0) for s in STATUSES}
        cols_html = "".join([
            f'<div style="flex:1;text-align:center;padding:10px;background:#f8f9fa;border-radius:6px;">'
            f'<div style="font-size:22px;font-weight:700;color:{STATUS_COLORS[s]};">{cnt}</div>'
            f'<div style="font-size:11.5px;color:#6b6b6b;margin-top:2px;">{s}</div></div>'
            for s,cnt in pipeline_data.items()
        ])
        total = len(apps)
        offer_pct = round(status_counts.get('Offer',0)/max(total,1)*100,1)
        iv_pct    = round(status_counts.get('Interview',0)/max(total,1)*100,1)
        st.markdown(f"""
        <div class="jt-card">
            <div class="jt-card-title">📊 Application Pipeline</div>
            <div style="display:flex;gap:8px;margin-bottom:14px;">{cols_html}</div>
            <div style="margin-top:6px;">
                <div style="display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:3px;">
                    <span>Offer Rate</span><span style="font-weight:700;color:#388E3C;">{offer_pct}%</span>
                </div>
                <div style="height:6px;background:#e9ecef;border-radius:3px;margin-bottom:8px;">
                    <div style="width:{min(offer_pct,100)}%;height:100%;background:#388E3C;border-radius:3px;"></div>
                </div>
                <div style="display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:3px;">
                    <span>Interview Rate</span><span style="font-weight:700;color:#7B1FA2;">{iv_pct}%</span>
                </div>
                <div style="height:6px;background:#e9ecef;border-radius:3px;">
                    <div style="width:{min(iv_pct,100)}%;height:100%;background:#7B1FA2;border-radius:3px;"></div>
                </div>
            </div>
        </div>
        """, unsafe_allow_html=True)

        # Recent apps card — HTML only
        if apps:
            rows_html = "".join([
                f'<div class="app-card" style="margin-bottom:8px;">'
                f'<div style="display:flex;justify-content:space-between;align-items:center;">'
                f'<div><div class="app-title">{a["JobTitle"]}</div>'
                f'<div class="app-sub">🏢 {a["CompanyName"]} &nbsp;·&nbsp; '
                f'{"🌐 " + a["ExternalSource"] if a.get("ExternalSource") else "🏫 JobTrack"}'
                f' &nbsp;·&nbsp; 📅 {fmt_date(a["DateApplied"])}</div></div>'
                f'<div style="flex-shrink:0;">{STATUS_BADGE.get(a["Status"],"")}</div>'
                f'</div></div>'
                for a in apps[:5]
            ])
            st.markdown(f"""
            <div class="jt-card">
                <div class="jt-card-title">📋 Recent Applications</div>
                {rows_html}
            </div>
            """, unsafe_allow_html=True)
            if st.button("View All Applications →", key="dash_all_apps"):
                nav_to('applications')
        else:
            st.info("No applications logged yet. Start tracking your job search!")
            if st.button("➕ Log First Application", key="dash_first"):
                nav_to('applications')


    with col_r:
        if student.get('AdvisorName'):
            adv_init = ''.join(w[0].upper() for w in student['AdvisorName'].split()[:2])
            st.markdown(f"""
            <div class="jt-card">
                <div class="jt-card-title">👩‍🏫 My Advisor</div>
                <div style="display:flex;align-items:center;gap:12px;">
                    <div style="width:44px;height:44px;background:rgba(106,0,50,.12);color:#6a0032;
                                border-radius:50%;display:flex;align-items:center;justify-content:center;
                                font-weight:700;font-size:16px;flex-shrink:0;">{adv_init}</div>
                    <div>
                        <div style="font-weight:600;font-size:14px;color:#1a1a2e;">{student['AdvisorName']}</div>
                        <div style="font-size:12px;color:#6b6b6b;">{student.get('AdvisorDept','Career Services')}</div>
                        <div style="font-size:12px;color:#6b6b6b;">{student.get('AdvisorEmail','')}</div>
                    </div>
                </div>
            </div>
            """, unsafe_allow_html=True)

        notes = db.get_student_advisor_notes(sid)
        if notes:
            notes_html = "".join([
                f'<div class="note-card {"note-flag" if n["InterventionFlag"] else ""}">'
                f'<div style="display:flex;justify-content:space-between;margin-bottom:3px;">'
                f'<span style="font-size:12px;font-weight:600;color:#6a0032;">{n["AdvisorName"] or "Advisor"}</span>'
                f'<span style="font-size:11px;color:#9b9b9b;">{fmt_date(n["DateCreated"])}</span></div>'
                f'<div style="font-size:13px;color:#495057;line-height:1.5;">{n["Note_content"]}</div>'
                f'</div>'
                for n in notes[:3]
            ])
            st.markdown(f"""
            <div class="jt-card">
                <div class="jt-card-title">📝 Advisor Notes</div>
                {notes_html}
            </div>
            """, unsafe_allow_html=True)

        goal = 20
        pct  = min(round(total/goal*100), 100)
        st.markdown(f"""
        <div class="jt-card">
            <div class="jt-card-title">📈 Progress</div>
            <div style="display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:3px;">
                <span>Apps ({total}/{goal} goal)</span><span style="font-weight:700;">{pct}%</span>
            </div>
            <div style="height:7px;background:#e9ecef;border-radius:3px;">
                <div style="width:{pct}%;height:100%;background:#6a0032;border-radius:3px;"></div>
            </div>
        </div>
        """, unsafe_allow_html=True)


def student_jobs():
    page_header("📌 Job Board", "Employer-submitted opportunities reviewed by CMU Career Services")
    st.markdown("""
    <div class="jt-info">
        <b>How this works:</b> Employers contact CMU Career Services with open positions.
        Career Services reviews and publishes them here. <b>Apply directly</b> using the employer
        contact or career link below, then come back to <b>My Applications</b> to log and track it.
    </div>
    """, unsafe_allow_html=True)

    c1,c2,c3 = st.columns([3,1,1])
    with c1: search = st.text_input("🔍 Search title, company, location, keyword", placeholder="e.g. Python, Detroit, Google...")
    with c2: type_filter = st.selectbox("Job Type", ["All"]+JOB_TYPES)
    with c3: dl_filter = st.selectbox("Deadline", ["All","Next 30 days","Next 60 days"])

    jobs = db.get_active_jobs(search=search, job_type=type_filter)
    if dl_filter == "Next 30 days":
        jobs = [j for j in jobs if j['Deadline'] and (j['Deadline']-date.today()).days<=30]
    elif dl_filter == "Next 60 days":
        jobs = [j for j in jobs if j['Deadline'] and (j['Deadline']-date.today()).days<=60]

    st.markdown(f"**{len(jobs)} active listing(s)**")
    st.markdown("---")
    if not jobs:
        st.info("No listings match your search."); return

    for job in jobs:
        jtype = job.get('JobType','Internship')
        bc    = JOB_TYPE_COLORS.get(jtype,'#6a0032')
        c_link = career_link(job.get('EmployerEmail',''), job.get('CompanyName',''))
        with st.container():
            col1, col2 = st.columns([4,1])
            with col1:
                st.markdown(
                    f"**{job['JobTitle']}** &nbsp;"
                    f"<span style='background:{bc};color:#fff;padding:2px 9px;"
                    f"border-radius:10px;font-size:0.75rem;font-weight:600;'>{jtype}</span>",
                    unsafe_allow_html=True
                )
                st.markdown(
                    f"🏢 **{job['CompanyName']}** &nbsp;·&nbsp; "
                    f"📍 {job.get('Location','—')} &nbsp;·&nbsp; "
                    f"📅 Deadline: **{fmt_date(job['Deadline'])}**"
                )
                contact_line = ""
                if job.get('EmployerEmail'):
                    contact_line = f"📧 [{job.get('EmployerContact','')} — {job['EmployerEmail']}](mailto:{job['EmployerEmail']})"
                elif job.get('EmployerContact'):
                    contact_line = f"👤 {job['EmployerContact']}"
                if contact_line:
                    st.markdown(contact_line)
                # Career page link
                st.markdown(f"🔗 [Apply at {job.get('CompanyName','Company')} Careers]({c_link})", unsafe_allow_html=False)
                if job.get('Description'):
                    with st.expander("View Description"):
                        st.write(job['Description'])
            with col2:
                st.markdown("<br>", unsafe_allow_html=True)
                if st.button("📋 Log Application", key=f"track_{job['JobID']}",
                             help="Applied? Log it in My Applications."):
                    nav_to('applications')
            st.markdown("---")


def student_applications():
    sid = st.session_state.user_id
    page_header("📋 My Applications", "Track, update, and manage your job applications")

    apps          = db.get_student_applications(sid)
    status_counts = {r['Status']: r['cnt'] for r in db.get_student_app_status_counts(sid)}
    total = len(apps)
    resp_rate = round((status_counts.get('Interview',0)+status_counts.get('Offer',0))/max(total,1)*100)

    c1,c2,c3,c4 = st.columns(4)
    with c1: metric_card("Total", total, "maroon")
    with c2: metric_card("Interview", status_counts.get('Interview',0), "gold")
    with c3: metric_card("Offers", status_counts.get('Offer',0), "green")
    with c4: metric_card("Response Rate", f"{resp_rate}%", "blue")
    st.markdown("<br>", unsafe_allow_html=True)

    tab_list, tab_add = st.tabs(["📋 All Applications", "➕ Log Application"])

    with tab_list:
        if not apps:
            st.info("No applications yet. Use '➕ Log Application' to start tracking.")
        else:
            cf, cs = st.columns([2,1])
            with cf: s_app = st.text_input("🔍 Search by title or company", key="app_search")
            with cs: s_status = st.selectbox("Status", ["All"]+STATUSES, key="app_status_f")

            filtered = apps
            if s_app:
                filtered = [a for a in filtered if
                            s_app.lower() in (a['JobTitle'] or '').lower() or
                            s_app.lower() in (a['CompanyName'] or '').lower()]
            if s_status != "All":
                filtered = [a for a in filtered if a['Status']==s_status]

            st.markdown(f"**{len(filtered)} application(s)**")
            for app in filtered:
                src = app.get('ExternalSource') or 'JobTrack'
                badge = STATUS_BADGE.get(app['Status'], app['Status'])
                src_label = f"🌐 {src}" if src != 'JobTrack' else "🏫 JobTrack"
                with st.expander(
                    f"**{app['JobTitle']}** @ {app['CompanyName']}  ·  {src}  |  {app['Status']}  |  {fmt_date(app['DateApplied'])}"
                ):
                    c1,c2,c3 = st.columns([2,2,1])
                    with c1:
                        st.markdown(f"""
                        <div class="app-card">
                            <div class="app-title">{app['JobTitle']}</div>
                            <div class="app-sub">🏢 {app['CompanyName']}</div>
                            <div class="app-sub">📅 Applied: {fmt_date(app['DateApplied'])}</div>
                            <div class="app-sub">🔄 Updated: {fmt_date(app['LastUpdated'])}</div>
                            <div class="app-sub">{src_label}</div>
                        </div>
                        """, unsafe_allow_html=True)
                        if app.get('ExternalURL'):
                            st.markdown(f"🔗 [View posting]({app['ExternalURL']})")
                    with c2:
                        new_s = st.selectbox("Update Status", STATUSES,
                                             index=STATUSES.index(app['Status']),
                                             key=f"status_{app['ApplicationID']}")
                        if st.button("💾 Save", key=f"save_{app['ApplicationID']}"):
                            db.update_application_status(app['ApplicationID'], sid, new_s)
                            st.success("Status updated!"); st.rerun()
                    with c3:
                        st.markdown("<br><br>", unsafe_allow_html=True)
                        if st.button("🗑️ Delete", key=f"del_{app['ApplicationID']}"):
                            db.delete_application(app['ApplicationID'], sid)
                            st.success("Deleted."); st.rerun()

                    # ── Advisor Notes for this application ──────────
                    app_notes = db.get_app_advising_notes(app['ApplicationID'])
                    if app_notes:
                        st.markdown('<hr style="border:none;border-top:1px solid #eee;margin:10px 0 8px;">', unsafe_allow_html=True)
                        notes_html = "".join([
                            f'<div style="background:{"#fff3cd" if n["InterventionFlag"] else "#f8f9fa"};'
                            f'border-left:3px solid {"#ffc107" if n["InterventionFlag"] else "#6a0032"};'
                            f'border-radius:6px;padding:9px 12px;margin-bottom:6px;">'
                            f'<div style="display:flex;justify-content:space-between;margin-bottom:3px;">'
                            f'<span style="font-size:12px;font-weight:600;color:#6a0032;">'
                            f'{"⚠️ " if n["InterventionFlag"] else "📝 "}{n["AdvisorName"] or "Advisor"}</span>'
                            f'<span style="font-size:11px;color:#9b9b9b;">{fmt_date(n["DateCreated"])}</span></div>'
                            f'<div style="font-size:13px;color:#495057;line-height:1.5;">{n["Note_content"]}</div>'
                            f'</div>'
                            for n in app_notes
                        ])
                        st.markdown(f'<div style="margin-top:4px;"><div style="font-size:12px;font-weight:600;color:#6b6b6b;margin-bottom:6px;">📋 ADVISOR NOTES FOR THIS APPLICATION</div>{notes_html}</div>', unsafe_allow_html=True)

    with tab_add:
        st.subheader("Log a New Application")
        st.caption("Record any job you applied to — LinkedIn, Indeed, Handshake, career fairs, company websites, referrals, or anywhere else.")
        with st.form("add_ext_app"):
            c1,c2 = st.columns(2)
            with c1:
                ext_title   = st.text_input("Job Title *", placeholder="e.g. Software Engineer Intern")
                ext_company = st.text_input("Company Name *", placeholder="e.g. Google")
                ext_source  = st.selectbox("Where did you apply?", SOURCES)
            with c2:
                ext_url    = st.text_input("Job Posting URL (optional)", placeholder="https://...")
                ext_date   = st.date_input("Date Applied", value=date.today())
                ext_status = st.selectbox("Current Status", STATUSES)
            if st.form_submit_button("➕ Log Application", use_container_width=True):
                if not ext_title.strip() or not ext_company.strip():
                    st.error("Job Title and Company Name are required.")
                else:
                    db.add_external_application(
                        sid, ext_title.strip(), ext_company.strip(),
                        ext_source, ext_url.strip() or None, ext_date, ext_status
                    )
                    st.success(f"✅ Logged **{ext_title}** at **{ext_company}** ({ext_source})!")
                    st.rerun()


def student_interviews():
    sid        = st.session_state.user_id
    interviews = db.get_student_interviews(sid)
    upcoming   = [i for i in interviews if i['InterviewDate'] >= date.today()] if interviews else []
    past       = [i for i in interviews if i['InterviewDate'] <  date.today()] if interviews else []

    page_header("🗓️ My Interviews", "Manage your interview schedule and preparation notes")

    # ── Interview Reminder Alerts ──────────────────────────────
    upcoming_7 = sorted(
        [i for i in interviews if 0 <= (i['InterviewDate'] - date.today()).days <= 7],
        key=lambda x: x['InterviewDate']
    ) if interviews else []
    if upcoming_7:
        for iv in upcoming_7:
            days = (iv['InterviewDate'] - date.today()).days
            if days == 0:
                bg, border, icon, urgency = '#fff3cd', '#e65100', '🔴', 'TODAY'
            elif days == 1:
                bg, border, icon, urgency = '#fff3cd', '#f57c00', '🟠', 'TOMORROW'
            elif days <= 3:
                bg, border, icon, urgency = '#fff8e1', '#ffc107', '🟡', f'in {days} days'
            else:
                bg, border, icon, urgency = '#e8f5e9', '#388e3c', '🟢', f'in {days} days'
            st.markdown(f"""
            <div style="background:{bg};border-left:4px solid {border};border-radius:8px;
                        padding:12px 16px;margin-bottom:8px;display:flex;align-items:center;gap:12px;">
                <div style="font-size:22px;">{icon}</div>
                <div style="flex:1;">
                    <div style="font-weight:700;font-size:14px;color:#1a1a2e;">
                        Interview Reminder &nbsp;·&nbsp;
                        <span style="color:{border};">{urgency.upper()}</span>
                    </div>
                    <div style="font-size:13px;color:#495057;margin-top:2px;">
                        <b>{iv['JobTitle']}</b> at <b>{iv['CompanyName']}</b>
                        &nbsp;·&nbsp; {iv['InterviewType']}
                        &nbsp;·&nbsp; 📅 {iv['InterviewDate'].strftime('%A, %b %d %Y')}
                    </div>
                </div>
            </div>
            """, unsafe_allow_html=True)

    apps = db.get_student_applications(sid)
    iv_rate = round(len(interviews)/max(len(apps),1)*100) if apps else 0
    c1,c2,c3,c4 = st.columns(4)
    with c1: metric_card("Total Interviews", len(interviews), "maroon")
    with c2: metric_card("Upcoming", len(upcoming), "gold")
    with c3: metric_card("Completed", len(past), "plain")
    with c4: metric_card("Interview Rate", f"{iv_rate}%", "blue")
    st.markdown("<br>", unsafe_allow_html=True)

    tab_list, tab_add = st.tabs(["🗓️ Schedule", "➕ Log Interview"])

    with tab_list:
        if not interviews:
            st.info("No interviews yet. Log one in the '➕ Log Interview' tab!")
        else:
            if upcoming:
                st.subheader("📅 Upcoming")
                for iv in upcoming:
                    days = (iv['InterviewDate']-date.today()).days
                    days_txt = "Today!" if days==0 else f"in {days} day{'s' if days!=1 else ''}"
                    with st.expander(f"**{iv['JobTitle']}** @ {iv['CompanyName']}  ·  {fmt_date(iv['InterviewDate'])} ({days_txt})  ·  {iv['InterviewType']}"):
                        c1,c2 = st.columns([3,1])
                        with c1:
                            st.write(f"**Type:** {iv['InterviewType']}")
                            st.write(f"**Date:** {fmt_date(iv['InterviewDate'])}")
                            if iv.get('MeetingLink'):
                                st.markdown(f"**Meeting Link:** [{iv['MeetingLink']}]({iv['MeetingLink']})")
                            if iv.get('FeedbackNotes'):
                                st.write(f"**Prep Notes:** {iv['FeedbackNotes']}")
                        with c2:
                            if st.button("🗑️ Delete", key=f"div_{iv['InterviewID']}"):
                                db.delete_interview(iv['InterviewID']); st.rerun()
            if past:
                st.subheader("🕐 Past Interviews")
                for iv in past:
                    with st.expander(f"**{iv['JobTitle']}** @ {iv['CompanyName']}  ·  {fmt_date(iv['InterviewDate'])}  ·  {iv['InterviewType']}"):
                        c1,c2 = st.columns([3,1])
                        with c1:
                            st.write(f"**Type:** {iv['InterviewType']}")
                            if iv.get('FeedbackNotes'):
                                st.write(f"**Notes:** {iv['FeedbackNotes']}")
                        with c2:
                            if st.button("🗑️ Delete", key=f"piv_{iv['InterviewID']}"):
                                db.delete_interview(iv['InterviewID']); st.rerun()

    with tab_add:
        st.subheader("Log an Interview")
        apps_dd = db.get_student_applications_for_dropdown(sid)
        if not apps_dd:
            st.warning("No applications found. Add applications first.")
        else:
            app_options = {r['Label']: r['ApplicationID'] for r in apps_dd}
            with st.form("add_iv_form"):
                sel_app = st.selectbox("Application *", list(app_options.keys()))
                c1,c2   = st.columns(2)
                with c1:
                    iv_date = st.date_input("Interview Date *", value=date.today())
                    iv_type = st.selectbox("Type *", INTERVIEW_TYPES)
                with c2:
                    iv_link = st.text_input("Meeting Link (optional)", placeholder="https://zoom.us/...")
                iv_notes = st.text_area("Notes (optional)",
                                        placeholder="Key talking points, outcomes, things to remember...")
                if st.form_submit_button("✅ Log Interview", use_container_width=True):
                    db.add_interview(app_options[sel_app], iv_date, iv_type, iv_link, iv_notes)
                    db.update_application_status(app_options[sel_app], sid, 'Interview')
                    st.success("✅ Interview logged! Application status set to 'Interview'."); st.rerun()


def student_profile():
    sid     = st.session_state.user_id
    student = db.get_student(sid)
    if not student:
        st.error("Profile not found."); return
    page_header("👤 My Profile", "Update your personal information and account settings")

    tab_profile, tab_pw = st.tabs(["📝 Profile Information", "🔑 Change Password"])

    with tab_profile:
        # Avatar info card — pure HTML, single call
        init = ''.join(w[0].upper() for w in f"{student['FirstName']} {student['LastName']}".split()[:2])
        st.markdown(f"""
        <div class="jt-card">
            <div style="display:flex;align-items:center;gap:16px;">
                <div style="width:56px;height:56px;background:linear-gradient(135deg,#6a0032,#9b0047);
                            color:#fff;border-radius:50%;display:flex;align-items:center;
                            justify-content:center;font-weight:700;font-size:20px;flex-shrink:0;">{init}</div>
                <div>
                    <div style="font-size:18px;font-weight:700;color:#1a1a2e;">{student['FirstName']} {student['LastName']}</div>
                    <div style="font-size:13px;color:#6b6b6b;">{student.get('Major','—')} · Class of {student.get('GraduationDate','—')}</div>
                    <div style="font-size:13px;color:#6b6b6b;">{student['Email']}</div>
                    {'<div style="font-size:13px;color:#6b6b6b;">Advisor: ' + student['AdvisorName'] + '</div>' if student.get('AdvisorName') else ''}
                </div>
            </div>
        </div>
        """, unsafe_allow_html=True)

        # Edit form
        with st.form("profile_form"):
            c1,c2 = st.columns(2)
            with c1:
                first = st.text_input("First Name", value=student['FirstName'])
                last  = st.text_input("Last Name",  value=student['LastName'])
            with c2:
                major_idx = MAJORS.index(student.get('Major','')) if student.get('Major','') in MAJORS else 0
                major = st.selectbox("Major", MAJORS, index=major_idx)
                grad  = st.text_input("Graduation Date", value=student.get('GraduationDate',''))
            st.text_input("Email (read-only)", value=student['Email'], disabled=True)
            if st.form_submit_button("💾 Save Profile"):
                db.update_student_profile(sid, first, last, major, grad)
                st.success("✅ Profile updated!"); st.rerun()

    with tab_pw:
        with st.form("pw_form"):
            current_pw = st.text_input("Current Password", type="password")
            new_pw     = st.text_input("New Password",     type="password")
            confirm_pw = st.text_input("Confirm New Password", type="password")
            if st.form_submit_button("🔑 Change Password"):
                if current_pw != student['Password']:
                    st.error("Current password is incorrect.")
                elif new_pw != confirm_pw:
                    st.error("New passwords do not match.")
                elif len(new_pw) < 6:
                    st.error("Password must be at least 6 characters.")
                else:
                    db.update_password('Student','StudentId', sid, new_pw)
                    st.success("✅ Password changed!")


# ============================================================
# ══════════════  ADVISOR  ══════════════
# ============================================================

def advisor_sidebar():
    sidebar_header()
    cur = st.session_state.page
    st.sidebar.markdown('<span class="nav-lbl">Navigation</span>', unsafe_allow_html=True)
    _nav_button("🏠  Dashboard",       "anav_dash",  "dashboard", cur)
    _nav_button("👨‍🎓  My Students",   "anav_stu",   "students",  cur)
    _nav_button("📝  Advising Notes",  "anav_notes", "notes",     cur)
    st.sidebar.markdown('<div style="height:14px;"></div>', unsafe_allow_html=True)
    if st.sidebar.button("↩  Sign Out", key="adv_out", use_container_width=True, type="secondary"):
        logout()


def advisor_dashboard():
    aid    = st.session_state.user_id
    advisor = db.get_advisor(aid)
    if not advisor: st.error("Advisor not found."); return
    stats = db.get_advisor_dashboard_stats(aid)
    page_header("👩‍🏫 Advisor Dashboard",
                f"{advisor['firstName']} {advisor['LastName']} · {advisor.get('Department','Career Services')}")

    c1,c2,c3,c4 = st.columns(4)
    with c1: metric_card("👨‍🎓 Assigned Students", stats['students'], "maroon")
    with c2: metric_card("🚩 Need Intervention",  stats['interventions'], "gold")
    with c3: metric_card("📝 Total Notes",        stats['notes'], "plain")
    with c4: metric_card("🎉 Students w/ Offers", stats['offers'], "green")
    st.markdown("<br>", unsafe_allow_html=True)

    col_l, col_r = st.columns([3,2])
    with col_l:
        students = db.get_advisor_students(aid)
        if students:
            df = pd.DataFrame(students)
            df.insert(0,'Student', df['FirstName']+' '+df['LastName'])
            df = df[['Student','Major','GraduationDate','TotalApps','Interviews','Offers','Flags']]
            df.columns = ['Student','Major','Graduation','Total Apps','Interviews','Offers','⚑ Flags']
            st.subheader("👨‍🎓 Student Pipeline")
            st.dataframe(df, use_container_width=True, hide_index=True)
        else:
            st.info("No students assigned.")

    with col_r:
        flagged = db.get_intervention_students(aid)
        if flagged:
            flags_html = "".join([
                f'<div class="note-card note-flag">'
                f'<div style="font-weight:600;font-size:13px;">⚠️ {s["FirstName"]} {s["LastName"]} — {s["Major"]}</div>'
                f'<div style="font-size:12px;color:#495057;margin-top:4px;">{s["Note_content"][:110]}...</div>'
                f'<div style="font-size:11px;color:#9b9b9b;margin-top:3px;">{fmt_date(s["DateCreated"])}</div>'
                f'</div>'
                for s in flagged[:5]
            ])
            st.markdown(f"""
            <div class="jt-card">
                <div class="jt-card-title">🚩 Intervention Alerts</div>
                {flags_html}
            </div>
            """, unsafe_allow_html=True)

        no_apps = db.get_students_with_no_apps(aid)
        if no_apps:
            st.warning(f"⚠️ **{len(no_apps)} student(s)** have zero applications!")
            for s in no_apps:
                st.markdown(f"- {s['FirstName']} {s['LastName']} ({s['Major']}, {s['GraduationDate']})")


def advisor_students():
    aid = st.session_state.user_id
    page_header("👨‍🎓 My Students", "View and add advising notes per application")
    students = db.get_advisor_students(aid)
    if not students: st.info("No students assigned."); return

    search = st.text_input("🔍 Search by name or major")
    if search:
        students = [s for s in students if
                    search.lower() in s['FirstName'].lower() or
                    search.lower() in s['LastName'].lower() or
                    (s['Major'] and search.lower() in s['Major'].lower())]
    st.markdown(f"**{len(students)} student(s)**")

    for s in students:
        flag_icon = "🚩 " if s['Flags'] and int(s['Flags']) > 0 else ""
        with st.expander(
            f"{flag_icon}**{s['FirstName']} {s['LastName']}**  ·  {s['Major']}  ·  "
            f"{s['GraduationDate']}  ·  📋 {s['TotalApps']} apps  ·  🎉 {s['Offers']} offers"
        ):
            apps = db.get_student_apps_for_advisor(s['StudentId'])
            if not apps:
                st.warning("⚠️ This student has not applied to any positions yet.")
            else:
                st.markdown(
                    f'<div style="font-size:12px;font-weight:600;color:#6b6b6b;'
                    f'letter-spacing:0.6px;text-transform:uppercase;margin-bottom:8px;">'
                    f'📋 {len(apps)} Application(s) — click to view notes & add new</div>',
                    unsafe_allow_html=True
                )
                for app in apps:
                    app_notes = db.get_notes_for_application_advisor(app['ApplicationID'], aid)
                    note_count = len(app_notes) if app_notes else 0
                    src = app.get('ExternalSource') or 'JobTrack'
                    badge = STATUS_BADGE.get(app['Status'], app['Status'])

                    with st.expander(
                        f"**{app['JobTitle']}** @ {app['CompanyName']}  ·  "
                        f"{app['Status']}  ·  {fmt_date(app['DateApplied'])}  ·  "
                        f"📝 {note_count} note{'s' if note_count != 1 else ''}"
                    ):
                        # ── Existing notes for this application ──────────
                        if app_notes:
                            for n in app_notes:
                                flag_c = 'note-flag' if n['InterventionFlag'] else ''
                                st.markdown(f"""
                                <div class="note-card {flag_c}" style="margin-bottom:8px;">
                                    <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
                                        <span style="font-size:12px;font-weight:600;color:#6a0032;">
                                            {'⚠️ INTERVENTION FLAG  ·  ' if n['InterventionFlag'] else '📝  '}
                                            {fmt_date(n['DateCreated'])}
                                        </span>
                                        <span style="font-size:11px;color:#9b9b9b;">Note #{n['NoteID']}</span>
                                    </div>
                                    <div style="font-size:13.5px;color:#495057;line-height:1.5;">
                                        {n['Note_content']}
                                    </div>
                                </div>
                                """, unsafe_allow_html=True)
                                dc1, dc2 = st.columns([5, 1])
                                with dc2:
                                    if st.button("🗑️", key=f"del_n_{n['NoteID']}_{app['ApplicationID']}",
                                                 help="Delete this note"):
                                        db.delete_advising_note(n['NoteID'], aid)
                                        st.rerun()
                        else:
                            st.caption("No notes yet for this application.")

                        st.markdown('<hr style="border:none;border-top:1px solid #eee;margin:10px 0 8px;">', unsafe_allow_html=True)

                        # ── Add note form for THIS application ────────────
                        with st.form(f"note_{s['StudentId']}_{app['ApplicationID']}"):
                            st.markdown(f'<div style="font-size:12px;font-weight:600;color:#6a0032;margin-bottom:4px;">➕ Add Note for this Application</div>', unsafe_allow_html=True)
                            note_content = st.text_area("Note *",
                                placeholder=f"Advising note for {app['JobTitle']} @ {app['CompanyName']}...",
                                height=90, key=f"nc_{s['StudentId']}_{app['ApplicationID']}")
                            flag_int = st.checkbox("🚩 Flag for Intervention",
                                                   key=f"fi_{s['StudentId']}_{app['ApplicationID']}")
                            if st.form_submit_button("📝 Save Note", use_container_width=True):
                                if not note_content.strip():
                                    st.error("Note cannot be empty.")
                                else:
                                    db.add_advising_note(
                                        aid, s['StudentId'],
                                        note_content.strip(), flag_int,
                                        app['ApplicationID']   # always linked to this app
                                    )
                                    st.success("✅ Note saved!")
                                    st.rerun()


def advisor_notes():
    aid = st.session_state.user_id
    page_header("📝 Advising Notes", "View, edit, and manage all advising notes")
    tab_all, tab_flag = st.tabs(["📋 All Notes","🚩 Intervention Flags"])

    with tab_all:
        notes = db.get_advisor_notes(aid)
        if not notes:
            st.info("No notes yet. Go to 'My Students' to add notes."); return
        search = st.text_input("🔍 Search by student or content", key="notes_s")
        if search:
            notes = [n for n in notes if search.lower() in n['StudentName'].lower() or
                     search.lower() in n['Note_content'].lower()]
        st.markdown(f"**{len(notes)} note(s)**")
        for n in notes:
            flag_c  = 'note-flag' if n['InterventionFlag'] else ''
            app_ctx = f"{n['JobTitle']} @ {n['CompanyName']}" if n.get('JobTitle') else '—'
            preview = n['Note_content'][:55]+'…' if len(n['Note_content'])>55 else n['Note_content']
            with st.expander(
                f"{'🚩 ' if n['InterventionFlag'] else '📝 '}**{n['StudentName']}**  ·  "
                f"{app_ctx}  ·  {fmt_date(n['DateCreated'])}  ·  {preview}"
            ):
                # Application context banner
                if n.get('JobTitle'):
                    st.markdown(
                        f'<div style="background:#f0f4ff;border-left:3px solid #1976D2;'
                        f'border-radius:6px;padding:7px 12px;margin-bottom:8px;font-size:13px;">'
                        f'🔗 <b>Application:</b> {n["JobTitle"]} @ {n["CompanyName"]}</div>',
                        unsafe_allow_html=True
                    )
                else:
                    st.markdown(
                        '<div style="background:#fff3cd;border-left:3px solid #ffc107;'
                        'border-radius:6px;padding:7px 12px;margin-bottom:8px;font-size:13px;">'
                        '⚠️ <b>No application linked</b> (general student note)</div>',
                        unsafe_allow_html=True
                    )
                # Student email link
                student_email = n.get('StudentEmail') or n.get('Email', '')
                if student_email:
                    st.markdown(
                        f'<div style="font-size:12.5px;color:#6b6b7b;margin-bottom:8px;">'
                        f'👤 <b>{n["StudentName"]}</b> · '
                        f'<a href="mailto:{student_email}" style="color:#6a0032;text-decoration:underline;">'
                        f'{student_email}</a></div>',
                        unsafe_allow_html=True
                    )
                c1, c2 = st.columns([4, 1])
                with c1:
                    st.markdown(
                        f'<div class="note-card {flag_c}">'
                        f'<div style="font-size:13.5px;color:#495057;">{n["Note_content"]}</div>'
                        f'</div>', unsafe_allow_html=True
                    )
                with c2:
                    if st.button("🗑️ Delete", key=f"dn_{n['NoteID']}"):
                        db.delete_advising_note(n['NoteID'], aid)
                        st.success("Deleted."); st.rerun()
                with st.form(f"edit_n_{n['NoteID']}"):
                    new_c = st.text_area("Edit Note", value=n['Note_content'], height=80, key=f"nc_{n['NoteID']}")
                    new_f = st.checkbox("🚩 Intervention", value=bool(n['InterventionFlag']), key=f"nf_{n['NoteID']}")
                    if st.form_submit_button("💾 Update"):
                        db.update_advising_note(n['NoteID'], new_c, new_f, aid)
                        st.success("Updated!"); st.rerun()

    with tab_flag:
        flagged = db.get_intervention_students(aid)
        if not flagged:
            st.success("✅ No students currently flagged for intervention!")
        else:
            st.warning(f"🚩 **{len(flagged)} student(s)** require follow-up:")
            for s in flagged:
                st.markdown(f"""
                <div class="note-card note-flag">
                    <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
                        <span style="font-weight:700;font-size:14px;">⚠️ {s['FirstName']} {s['LastName']}</span>
                        <span style="font-size:12px;color:#9b9b9b;">{fmt_date(s['DateCreated'])}</span>
                    </div>
                    <div style="font-size:12.5px;color:#6b6b6b;margin-bottom:4px;">{s['Major']} · <a href="mailto:{s['Email']}" style="color:#6a0032;text-decoration:underline;">{s['Email']}</a></div>
                    <div style="font-size:13px;color:#495057;">{s['Note_content']}</div>
                </div>
                """, unsafe_allow_html=True)


# ============================================================
# ══════════════  ADMIN  ══════════════
# ============================================================

def admin_sidebar():
    sidebar_header()
    cur = st.session_state.page
    st.sidebar.markdown('<span class="nav-lbl">Navigation</span>', unsafe_allow_html=True)
    _nav_button("🏠  Dashboard",   "dmnav_dash",  "dashboard", cur)
    _nav_button("📌  Job Board",   "dmnav_jobs",  "jobs",      cur)
    _nav_button("📊  Reports",     "dmnav_rep",   "reports",   cur)
    _nav_button("👥  Users",       "dmnav_users", "users",     cur)
    st.sidebar.markdown('<div style="height:14px;"></div>', unsafe_allow_html=True)
    if st.sidebar.button("↩  Sign Out", key="adm_out", use_container_width=True, type="secondary"):
        logout()


def admin_dashboard():
    aid   = st.session_state.user_id
    admin = db.get_admin(aid)
    if not admin: st.error("Admin not found."); return
    stats = db.get_system_stats()
    page_header("⚙️ Career Services Dashboard",
                f"Welcome, {admin['first_name']} {admin['LastName']} · {admin.get('Department','Career Services')}")

    c1,c2,c3,c4 = st.columns(4)
    with c1: metric_card("👨‍🎓 Total Students",          stats['students'],    "maroon")
    with c2: metric_card("📋 Total Applications",       stats['applications'], "gold")
    with c3: metric_card("📌 Active Listings",          stats['active_jobs'],  "green")
    with c4: metric_card("🎉 Offers Extended",          stats['offers'],       "blue")
    st.markdown("<br>", unsafe_allow_html=True)
    c5,c6,c7,c8 = st.columns(4)
    with c5: metric_card("🗓️ Interviews Ongoing",  stats['interviews'],   "plain")
    with c6: metric_card("🚩 Intervention Flags",  stats['interventions'],"plain")
    with c7: metric_card("👩‍🏫 Total Advisors",      stats['advisors'],    "plain")
    with c8: metric_card("📌 Total Job Posts",     stats['total_jobs'],  "plain")
    st.markdown("<br>", unsafe_allow_html=True)

    funnel = db.get_application_funnel()
    if funnel:
        df_f = pd.DataFrame(funnel)
        fig = px.bar(df_f, x='Status', y='cnt', color='Status',
                     color_discrete_map=STATUS_COLORS,
                     labels={'cnt':'Applications'}, title='Application Status Overview',
                     text='cnt')
        fig.update_traces(textposition='outside', textfont=dict(color='#1a1a2e', size=13))
        fig.update_layout(
            showlegend=False, plot_bgcolor='white', paper_bgcolor='white',
            height=340, margin=dict(l=60, r=20, t=55, b=60),
            font=dict(family='Inter,sans-serif', size=13, color='#1a1a2e'),
            title_font=dict(size=15, color='#1a1a2e'),
            xaxis=dict(title='Status', showticklabels=True,
                       tickfont=dict(size=13, color='#1a1a2e'),
                       title_font=dict(size=13, color='#1a1a2e')),
            yaxis=dict(title='Number of Applications', showticklabels=True,
                       tickfont=dict(size=12, color='#1a1a2e'),
                       title_font=dict(size=13, color='#1a1a2e'),
                       showgrid=True, gridcolor='#f0f0f0'),
        )
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("📋 Recent Applications (All Students)")
    recent = db.get_all_applications_admin()[:10]
    if recent:
        df = pd.DataFrame(recent)[['StudentName','Major','JobTitle','CompanyName','Source','Status','DateApplied']]
        df.columns = ['Student','Major','Job Title','Company','Source','Status','Applied']
        df['Applied'] = df['Applied'].apply(fmt_date)
        st.dataframe(df, use_container_width=True, hide_index=True)


def admin_jobs():
    aid = st.session_state.user_id
    page_header("📌 Job Board", "Register and manage employer-submitted positions for CMU students")
    st.markdown("""
    <div class="jt-admin-info">
        <b>Employer Submission Workflow:</b><br>
        1. Employer contacts CMU Career Services with an open position.<br>
        2. You review the submission and register it here with the employer's contact details.<br>
        3. The listing goes live on the student-facing Job Board immediately.<br>
        4. Students browse, apply directly with the employer, then log their applications in JobTrack.
    </div>
    """, unsafe_allow_html=True)

    tab_list, tab_add = st.tabs(["📌 All Listings","➕ Register Employer Submission"])

    with tab_list:
        jobs = db.get_all_job_postings()
        if not jobs:
            st.info("No listings yet.")
        else:
            cs, cf = st.columns([3,1])
            with cs: search = st.text_input("🔍 Search listings", placeholder="Company, title, location...")
            with cf: show_f = st.selectbox("Show", ["All","Active Only","Expired/Inactive"])

            if search:
                jobs = [j for j in jobs if
                        search.lower() in j['JobTitle'].lower() or
                        search.lower() in (j['CompanyName'] or '').lower() or
                        search.lower() in (j.get('Location') or '').lower()]
            if show_f == "Active Only":
                jobs = [j for j in jobs if j.get('IsActive') and j['Deadline'] and j['Deadline']>=date.today()]
            elif show_f == "Expired/Inactive":
                jobs = [j for j in jobs if not j.get('IsActive') or not j['Deadline'] or j['Deadline']<date.today()]

            all_j  = db.get_all_job_postings()
            act_c  = sum(1 for j in all_j if j.get('IsActive') and j['Deadline'] and j['Deadline']>=date.today())
            tot_c  = len(all_j)
            st.markdown(f"**{act_c} active** · **{tot_c-act_c} expired/inactive** · **{tot_c} total**")

            for job in jobs:
                ia  = bool(job.get('IsActive'))
                nex = job['Deadline'] and job['Deadline']>=date.today()
                if ia and nex:   si,sl = "🟢","Active"
                elif ia and not nex: si,sl = "🟡","Expired"
                else:            si,sl = "🔴","Inactive"

                with st.expander(
                    f"{si} **{job['JobTitle']}** @ {job['CompanyName']}  ·  "
                    f"{job.get('JobType','—')}  ·  {job.get('Location','—')}  ·  "
                    f"Deadline: {fmt_date(job['Deadline'])}  ·  👥 {job.get('Trackers',0)} tracking"
                ):
                    tv, te = st.tabs(["👁️ Details","✏️ Edit"])
                    with tv:
                        c1,c2 = st.columns(2)
                        with c1:
                            st.write(f"**Job Title:** {job['JobTitle']}")
                            st.write(f"**Company:** {job['CompanyName']}")
                            st.write(f"**Location:** {job.get('Location','—')}")
                            st.write(f"**Job Type:** {job.get('JobType','—')}")
                            st.write(f"**Status:** {sl}")
                        with c2:
                            st.write(f"**Posted:** {fmt_date(job['Posted'])}")
                            st.write(f"**Deadline:** {fmt_date(job['Deadline'])}")
                            st.write(f"**Employer Contact:** {job.get('EmployerContact','—')}")
                            st.write(f"**Employer Email:** {job.get('EmployerEmail','—')}")
                            st.write(f"**Students Tracking:** {job.get('Trackers',0)}")
                        if job.get('Description'):
                            st.write("**Description:**"); st.write(job['Description'])
                        st.markdown("---")
                        b1,b2 = st.columns(2)
                        with b1:
                            if st.button("🔴 Deactivate" if ia else "🟢 Activate", key=f"tog_{job['JobID']}"):
                                db.toggle_job_active(job['JobID'], not ia)
                                st.success(f"{'Deactivated' if ia else 'Activated'}."); st.rerun()
                        with b2:
                            if st.button("🗑️ Delete", key=f"delj_{job['JobID']}"):
                                db.delete_job_posting(job['JobID']); st.success("Deleted."); st.rerun()
                    with te:
                        with st.form(f"ej_{job['JobID']}"):
                            e1,e2 = st.columns(2)
                            with e1:
                                nt = st.text_input("Job Title",    value=job['JobTitle'])
                                nc = st.text_input("Company Name", value=job.get('CompanyName',''))
                                nl = st.text_input("Location",     value=job.get('Location',''))
                                njt= st.selectbox("Job Type", JOB_TYPES,
                                                  index=JOB_TYPES.index(job.get('JobType','Internship'))
                                                  if job.get('JobType') in JOB_TYPES else 0)
                            with e2:
                                dl_v = job['Deadline'] if isinstance(job['Deadline'],date) else date.today()
                                nd   = st.date_input("Deadline", value=dl_v)
                                nco  = st.text_input("Employer Contact", value=job.get('EmployerContact',''))
                                nem  = st.text_input("Employer Email",   value=job.get('EmployerEmail',''))
                            ndesc = st.text_area("Description", value=job.get('Description',''), height=100)
                            if st.form_submit_button("💾 Save Changes"):
                                db.update_job_posting(job['JobID'], nt.strip(), ndesc.strip(), nd,
                                                      nc.strip(), nl.strip(), njt, nco.strip(), nem.strip())
                                st.success("✅ Updated!"); st.rerun()

    with tab_add:
        st.subheader("Register New Employer Submission")
        st.caption("Fill in details from the employer. The listing will immediately appear on the student Job Board.")
        with st.form("cjf"):
            r1,r2 = st.columns(2)
            with r1:
                ttl = st.text_input("Job Title *",    placeholder="e.g. Software Engineer Intern")
                co  = st.text_input("Company Name *", placeholder="e.g. Ford Motor Company")
                loc = st.text_input("Location *",     placeholder="e.g. Dearborn, MI  or  Remote")
                jt  = st.selectbox("Job Type *",      JOB_TYPES)
            with r2:
                ec  = st.text_input("Employer Contact Name *", placeholder="e.g. Rachel Kim")
                ee  = st.text_input("Employer Email *",        placeholder="e.g. r.kim@company.com")
                po  = st.date_input("Date Received",           value=date.today())
                dl  = st.date_input("Application Deadline *",  value=date.today())
            desc = st.text_area("Job Description *",
                                placeholder="Paste the job description provided by the employer...", height=140)
            if st.form_submit_button("📌 Register on Job Board", use_container_width=True):
                if not ttl.strip() or not co.strip() or not loc.strip() or not desc.strip():
                    st.error("Title, Company, Location, and Description are required.")
                elif not ec.strip() or not ee.strip():
                    st.error("Employer Contact Name and Email are required.")
                elif dl <= po:
                    st.error("Deadline must be after the received date.")
                else:
                    db.create_job_posting(ttl.strip(), desc.strip(), po, dl,
                                          co.strip(), loc.strip(), jt, ec.strip(), ee.strip(), aid)
                    st.success(f"✅ **{ttl}** at **{co}** is now live on the Job Board!"); st.rerun()


def admin_users():
    page_header("👥 User Management", "Manage students, assign advisors, and administer advisor accounts")

    tab_stu, tab_adv = st.tabs(["🎓 Students", "👩‍🏫 Advisors"])

    # ── Students tab ──────────────────────────────────────────────
    with tab_stu:
        students = db.get_all_students_admin()
        advisors = db.get_all_advisors_admin() or []
        adv_map  = {a['AdvisorID']: f"{a['firstName']} {a['LastName']} ({a['Department']})" for a in advisors}
        adv_opts_labels = ["-- Unassigned --"] + [adv_map[a] for a in adv_map]
        adv_opts_ids    = [None] + list(adv_map.keys())

        c1, c2 = st.columns([3,1])
        with c1: search = st.text_input("🔍 Search students", placeholder="Name, email, or major…", key="um_stu_search")
        with c2: filter_unassigned = st.checkbox("Show unassigned only", key="um_unassigned")

        filtered = students or []
        if search:
            q = search.lower()
            filtered = [s for s in filtered if
                        q in (s['FirstName']+' '+s['LastName']).lower() or
                        q in (s['Email'] or '').lower() or
                        q in (s['Major'] or '').lower()]
        if filter_unassigned:
            filtered = [s for s in filtered if not s['AdvisorID']]

        st.markdown(f"**{len(filtered)} student(s)**")

        for s in filtered:
            with st.expander(
                f"**{s['FirstName']} {s['LastName']}** · {s['Major']} · {s['Email']} "
                f"· {'⚠️ Unassigned' if not s['AdvisorName'] else s['AdvisorName']}"
            ):
                ca, cb, cc = st.columns([2, 2, 1])
                with ca:
                    st.markdown(f"""
                    <div class="jt-card" style="margin-bottom:0;">
                        <div style="font-size:14px;font-weight:700;">{s['FirstName']} {s['LastName']}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:4px;">📧 {s['Email']}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:2px;">📚 {s['Major']}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:2px;">🎓 Graduates: {s['GraduationDate']}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:2px;">📋 Applications: {s['AppCount']}</div>
                    </div>
                    """, unsafe_allow_html=True)
                with cb:
                    cur_idx = adv_opts_ids.index(s['AdvisorID']) if s['AdvisorID'] in adv_opts_ids else 0
                    new_adv = st.selectbox("Assign Advisor", adv_opts_labels,
                                           index=cur_idx, key=f"adv_sel_{s['StudentId']}")
                    new_adv_id = adv_opts_ids[adv_opts_labels.index(new_adv)]
                    if st.button("💾 Save Assignment", key=f"adv_save_{s['StudentId']}"):
                        db.assign_advisor(s['StudentId'], new_adv_id)
                        st.success("Advisor updated!"); st.rerun()
                with cc:
                    st.markdown("<br>", unsafe_allow_html=True)
                    if st.button("🗑️ Delete", key=f"del_stu_{s['StudentId']}",
                                 help="Permanently delete this student and all their data"):
                        db.delete_student(s['StudentId'])
                        st.success("Student deleted."); st.rerun()

        st.markdown("---")
        with st.expander("➕ Add New Student Account"):
            with st.form("add_student_form"):
                c1,c2 = st.columns(2)
                with c1:
                    nfirst = st.text_input("First Name *")
                    nlast  = st.text_input("Last Name *")
                    nemail = st.text_input("CMU Email *")
                with c2:
                    nmajor = st.selectbox("Major *", ["-- Select --"] + MAJORS)
                    ngrad  = st.text_input("Graduation Date", placeholder="May 2026")
                    npwd   = st.text_input("Temp Password *", type="password", value="Password1!")
                adv_sel = st.selectbox("Assign Advisor", adv_opts_labels, key="new_stu_adv")
                adv_id  = adv_opts_ids[adv_opts_labels.index(adv_sel)]
                if st.form_submit_button("✅ Create Student"):
                    if not all([nfirst, nlast, nemail, nmajor != "-- Select --"]):
                        st.error("Please fill all required fields.")
                    elif db.email_exists(nemail):
                        st.error("Email already registered.")
                    else:
                        db.register_student(nfirst, nlast, nemail, npwd, nmajor, ngrad, adv_id)
                        st.success(f"Student {nfirst} {nlast} created!"); st.rerun()

    # ── Advisors tab ──────────────────────────────────────────────
    with tab_adv:
        advisors = db.get_all_advisors_admin()
        search_a = st.text_input("🔍 Search advisors", placeholder="Name, email, or department…", key="um_adv_search")

        filtered_a = advisors or []
        if search_a:
            q = search_a.lower()
            filtered_a = [a for a in filtered_a if
                          q in (a['firstName']+' '+a['LastName']).lower() or
                          q in (a['Email'] or '').lower() or
                          q in (a['Department'] or '').lower()]

        st.markdown(f"**{len(filtered_a)} advisor(s)**")

        for a in filtered_a:
            full = f"{a['firstName']} {a['LastName']}"
            with st.expander(f"**{full}** · {a['Department']} · {a['StudentCount']} student(s)"):
                c1, c2 = st.columns([3,1])
                with c1:
                    st.markdown(f"""
                    <div class="jt-card" style="margin-bottom:0;">
                        <div style="font-size:14px;font-weight:700;">{full}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:4px;">📧 {a['Email']}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:2px;">🏛️ {a['Department']}</div>
                        <div style="font-size:12.5px;color:#6b6b7b;margin-top:2px;">👨‍🎓 {a['StudentCount']} assigned students</div>
                    </div>
                    """, unsafe_allow_html=True)
                with c2:
                    st.markdown("<br>", unsafe_allow_html=True)
                    if st.button("🗑️ Remove", key=f"del_adv_{a['AdvisorID']}",
                                 help="Remove advisor (students become unassigned)"):
                        db.delete_advisor(a['AdvisorID'])
                        st.success("Advisor removed."); st.rerun()

        st.markdown("---")
        with st.expander("➕ Add New Advisor"):
            with st.form("add_advisor_form"):
                c1,c2 = st.columns(2)
                with c1:
                    af  = st.text_input("First Name *")
                    al  = st.text_input("Last Name *")
                    ae  = st.text_input("CMU Email *")
                with c2:
                    ad  = st.text_input("Department *", placeholder="Computer Science")
                    ap  = st.text_input("Temp Password *", type="password", value="Password1!")
                if st.form_submit_button("✅ Create Advisor"):
                    if not all([af, al, ae, ad]):
                        st.error("Please fill all required fields.")
                    elif db.email_exists(ae):
                        st.error("Email already registered.")
                    else:
                        db.add_advisor(af, al, ae, ap, ad)
                        st.success(f"Advisor {af} {al} created!"); st.rerun()


def admin_reports():
    page_header("📊 Reports & Analytics", "Placement statistics, application funnel, and advisor metrics")
    tab1,tab2,tab3,tab4 = st.tabs([
        "📊 Application Funnel","🏢 Company Analysis","👨‍🎓 Student Pipeline","👩‍🏫 Advisor Effectiveness"
    ])

    with tab1:
        st.subheader("Application Funnel Analysis")
        funnel  = db.get_application_funnel()
        monthly = db.get_monthly_applications()
        if funnel:
            df_f  = pd.DataFrame(funnel)
            total = df_f['cnt'].sum()
            df_f['Pct'] = (df_f['cnt']/total*100).round(1)
            # Single funnel chart — full width, no duplicate pie
            fig = go.Figure(go.Funnel(
                y=df_f['Status'], x=df_f['cnt'],
                textposition="inside", textinfo="value+percent initial",
                marker={"color":[STATUS_COLORS.get(s,'#888') for s in df_f['Status']]}
            ))
            fig.update_layout(
                title="Application Funnel — All Students",
                height=400, plot_bgcolor='white', paper_bgcolor='white',
                margin=dict(l=120, r=40, t=55, b=40),
                font=dict(family='Inter,sans-serif', size=13, color='#1a1a2e'),
                title_font=dict(size=15, color='#1a1a2e'),
                yaxis=dict(tickfont=dict(size=13, color='#1a1a2e')),
            )
            st.plotly_chart(fig, use_container_width=True)
            # Table removed — values shown inside funnel chart
        if monthly:
            df_m = pd.DataFrame(monthly)
            fig3 = px.line(df_m, x='Month', y='Applications',
                           title='Monthly Application Volume', markers=True,
                           color_discrete_sequence=['#6a0032'])
            fig3.update_layout(
                plot_bgcolor='white', paper_bgcolor='white', height=300,
                margin=dict(l=60, r=30, t=50, b=60),
                font=dict(family='Inter,sans-serif', size=13, color='#1a1a2e'),
                title_font=dict(size=14, color='#1a1a2e'),
                xaxis=dict(title='Month', showticklabels=True, tickangle=-30,
                           tickfont=dict(size=12, color='#1a1a2e'),
                           title_font=dict(size=13, color='#1a1a2e'),
                           showgrid=True, gridcolor='#ececec'),
                yaxis=dict(title='Applications', showticklabels=True,
                           tickfont=dict(size=12, color='#1a1a2e'),
                           title_font=dict(size=13, color='#1a1a2e'),
                           showgrid=True, gridcolor='#ececec'),
            )
            st.plotly_chart(fig3, use_container_width=True)

    with tab2:
        st.subheader("Company Hiring Metrics")
        co_data   = db.get_company_stats()
        placement = db.get_placement_list()
        if co_data:
            df_c = pd.DataFrame(co_data)
            _hbar = dict(
                plot_bgcolor='white', paper_bgcolor='white', height=400,
                margin=dict(l=150, r=30, t=50, b=60),
                showlegend=False,
                coloraxis_showscale=False,
                font=dict(family='Inter,sans-serif', size=12, color='#1a1a2e'),
                title_font=dict(size=14, color='#1a1a2e'),
                xaxis=dict(
                    showticklabels=True, tickfont=dict(size=12, color='#1a1a2e'),
                    title_font=dict(size=13, color='#1a1a2e'),
                    showgrid=True, gridcolor='#ececec', zeroline=True, zerolinecolor='#ccc',
                ),
                yaxis=dict(
                    showticklabels=True, tickfont=dict(size=12, color='#1a1a2e'),
                    title='',
                ),
            )
            c1,c2 = st.columns(2)
            with c1:
                fig = px.bar(df_c.head(10), y='CompanyName', x='TotalApps', orientation='h',
                             title='Top 10 Companies by Applications',
                             color_discrete_sequence=['#6a0032'])
                fig.update_layout(**_hbar, xaxis_title='Number of Applications')
                st.plotly_chart(fig, use_container_width=True)
            with c2:
                df_c2 = df_c[df_c['TotalApps'] >= 2].head(10)
                if not df_c2.empty:
                    fig2 = px.bar(df_c2, y='CompanyName', x='OfferRatePct', orientation='h',
                                  title='Offer Rate by Company (%)',
                                  color_discrete_sequence=['#388e3c'])
                    fig2.update_layout(**_hbar, xaxis_title='Offer Rate (%)')
                    st.plotly_chart(fig2, use_container_width=True)
            # Table removed — data already visible in the charts above
        if placement:
            st.subheader("🎉 Placement List — Students with Offers")
            df_p = pd.DataFrame(placement)[['StudentName','Major','GraduationDate','CompanyName','JobTitle','DateApplied']]
            df_p.columns = ['Student','Major','Graduation','Company','Job Title','Applied']
            df_p['Applied'] = df_p['Applied'].apply(fmt_date)
            st.dataframe(df_p, use_container_width=True, hide_index=True)

    with tab3:
        st.subheader("Full Student Application Pipeline")
        pipeline = db.get_full_student_pipeline()
        if pipeline:
            df_s = pd.DataFrame(pipeline)[['StudentName','Major','GraduationDate','Advisor',
                                           'TotalApps','Applied','Interviews','Offers']]
            df_s.columns = ['Student','Major','Graduation','Advisor','Total Apps','Applied','Interviews','Offers']
            c1,c2,c3 = st.columns(3)
            c1.metric("Students Tracked", len(df_s))
            c2.metric("In Interview Stage", int(df_s['Interviews'].sum()))
            c3.metric("With Offers", int(df_s['Offers'].sum()))
            

            cf1,cf2 = st.columns(2)
            with cf1:
                mf = st.selectbox("Filter by Major",   ["All"]+sorted(df_s['Major'].dropna().unique().tolist()))
            with cf2:
                af = st.selectbox("Filter by Advisor", ["All"]+sorted(df_s['Advisor'].dropna().unique().tolist()))
            if mf != "All": df_s = df_s[df_s['Major']==mf]
            if af != "All": df_s = df_s[df_s['Advisor']==af]
            st.dataframe(df_s, use_container_width=True, hide_index=True)

            st.subheader("Placement Rate by Major")
            all_pip = db.get_full_student_pipeline()
            df_all = pd.DataFrame(all_pip)[['StudentName','Major','Offers']]
            df_all.columns = ['Student','Major','Offers']
            ms = df_all.groupby('Major').agg(
                Students=('Student','count'),
                WithOffers=('Offers', lambda x:(x>0).sum())
            ).reset_index()
            ms['Placement Rate (%)'] = (ms['WithOffers']/ms['Students']*100).round(1)

            fig = px.bar(ms, x='Major', y='Placement Rate (%)',
                         title='Placement Rate by Major (%)',
                         color='Placement Rate (%)', color_continuous_scale=['#ffc107','#6a0032'],
                         text='Placement Rate (%)')
            fig.update_traces(texttemplate='%{text}%', textposition='outside')
            fig.update_layout(
                plot_bgcolor='white', paper_bgcolor='white', height=370,
                margin=dict(l=60, r=20, t=55, b=100),
                coloraxis_showscale=False,
                font=dict(family='Inter,sans-serif', size=12, color='#1a1a2e'),
                title_font=dict(size=14, color='#1a1a2e'),
                xaxis=dict(
                    title='Major', tickangle=-30,
                    tickfont=dict(size=11, color='#1a1a2e'),
                    title_font=dict(color='#1a1a2e'),
                ),
                yaxis=dict(
                    title='Placement Rate (%)',
                    tickfont=dict(size=11, color='#1a1a2e'),
                    title_font=dict(color='#1a1a2e'),
                    showgrid=True, gridcolor='#f0f0f0',
                ),
            )
            st.plotly_chart(fig, use_container_width=True)
            # Table removed — values shown as bar labels above

    with tab4:
        st.subheader("Advisor Performance Metrics")
        adv_data = db.get_advisor_effectiveness()
        if adv_data:
            df_a = pd.DataFrame(adv_data)[['AdvisorName','Department','Students','TotalNotes','Interventions']]
            df_a.columns = ['Advisor','Department','Students','Total Notes','Interventions']
            # Single chart — Students per Advisor (full width)
            fig = px.bar(df_a, x='Advisor', y='Students',
                         title='Students per Advisor',
                         color_discrete_sequence=['#6a0032'],
                         text='Students')
            fig.update_traces(textposition='outside', textfont=dict(color='#1a1a2e', size=12))
            fig.update_layout(
                plot_bgcolor='white', paper_bgcolor='white', height=360,
                margin=dict(l=60, r=20, t=55, b=100),
                font=dict(family='Inter,sans-serif', size=13, color='#1a1a2e'),
                title_font=dict(size=15, color='#1a1a2e'),
                showlegend=False,
                xaxis=dict(
                    title='Advisor',
                    tickangle=-25,
                    tickfont=dict(size=12, color='#1a1a2e'),
                    title_font=dict(size=13, color='#1a1a2e'),
                    showgrid=False,
                ),
                yaxis=dict(
                    title='Number of Students',
                    showticklabels=True,
                    tickfont=dict(size=12, color='#1a1a2e'),
                    title_font=dict(size=13, color='#1a1a2e'),
                    showgrid=True, gridcolor='#f0f0f0',
                ),
            )
            st.plotly_chart(fig, use_container_width=True)


# ============================================================
# MAIN ROUTER
# ============================================================
def force_sidebar_open():
    """Force the sidebar open via JS in case browser cached a collapsed state."""
    import streamlit.components.v1 as components
    components.html("""
    <script>
    (function() {
        function openSidebar() {
            var btn = parent.document.querySelector('[data-testid="stSidebarCollapsedControl"] button');
            if (btn) { btn.click(); }
        }
        // Try immediately and after short delay (Streamlit renders async)
        openSidebar();
        setTimeout(openSidebar, 300);
        setTimeout(openSidebar, 800);
    })();
    </script>
    """, height=0, scrolling=False)

def main():
    inject_css()
    force_sidebar_open()
    init_session()

    if not st.session_state.user:
        if st.session_state.get('show_register'):
            show_register()
        elif st.session_state.get('show_forgot'):
            show_forgot_password()
        else:
            show_login()
        return

    role = st.session_state.role
    page = st.session_state.page

    if role == 'student':
        student_sidebar()
        if   page == 'dashboard':    student_dashboard()
        elif page == 'jobs':         student_jobs()
        elif page == 'applications': student_applications()
        elif page == 'interviews':   student_interviews()
        elif page == 'profile':      student_profile()
        else:                        student_dashboard()

    elif role == 'advisor':
        advisor_sidebar()
        if   page == 'dashboard': advisor_dashboard()
        elif page == 'students':  advisor_students()
        elif page == 'notes':     advisor_notes()
        else:                     advisor_dashboard()

    elif role == 'admin':
        admin_sidebar()
        if   page == 'dashboard': admin_dashboard()
        elif page == 'jobs':      admin_jobs()
        elif page == 'reports':   admin_reports()
        elif page == 'users':     admin_users()
        else:                     admin_dashboard()

    else:
        st.error("Unknown role. Please sign out and try again.")
        if st.button("Log Out"): logout()


if __name__ == "__main__":
    main()
