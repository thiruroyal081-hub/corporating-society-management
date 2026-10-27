# Cooperative Society Management System

A beginner-friendly web application starter for cooperative society operations, built with Python Flask and PostgreSQL/Supabase.

## Current status

This is an **initial development scaffold**, not a production-ready financial system. The dashboard and member register are starter screens. Loan calculations, deposit interest, monthly recovery posting, accounting reports, authentication and audit controls must be implemented and tested before real use.

## Features planned

- Member master and nominee details
- Share capital and fee management
- Short-, medium- and long-term loans
- Thrift, RD and FD deposits
- Benevolent Fund and Family Welfare Fund
- Single-entry monthly recovery
- Receipts, daily demand and recovery reports
- Double-entry journal, day book, cash book, trial balance and P&L
- Role-based staff access, audit trail and backups

## Local setup (Windows)

1. Install Python 3.11 or newer.
2. Open Command Prompt in this repository folder.
3. Create a virtual environment:
   ```bat
   py -m venv .venv
   .venv\Scripts\activate
   ```
4. Install dependencies:
   ```bat
   pip install -r requirements.txt
   ```
5. Run the development app:
   ```bat
   python app.py
   ```
6. Open http://127.0.0.1:5000

The starter app uses demo data in memory. Data will reset when the app restarts. Do not enter real member or financial data yet.

## Database

`database/schema.sql` is a starting PostgreSQL schema. Review and apply it to a development Supabase/PostgreSQL project only after checking the schema and access policies. Never commit database passwords, API keys, member data or other secrets.

## Financial rules to confirm

Before implementing calculations, obtain the society's approved rules for interest method and day-count basis, installment allocation, fees, dividend, refunds, financial year, accounting treatment and nominee/death benefits. Have the society's accountant/auditor validate the resulting reports.

## Security checklist before real deployment

- Implement authentication and role-based authorization.
- Enable PostgreSQL row-level security where appropriate.
- Add server-side validation, CSRF protection, secure session settings and audit logging.
- Use HTTPS, backups and a tested restore process.
- Test duplicate submissions, reversals, reconciliation and balanced journal entries.
- Never use this scaffold for live transactions until independently reviewed and tested.
