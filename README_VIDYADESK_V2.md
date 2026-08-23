# VidyaDesk V2

VidyaDesk is being rebuilt as a mobile-first coaching institute management platform for Indian academic and competitive-exam institutes.

## V2 architecture

- `www/index.html` — minimal application entry point
- `www/app.js` — modular client application shell and role-based navigation
- `supabase_fresh_reset.sql` — destructive legacy application-schema reset; does not touch Supabase Auth internals or SMTP/email configuration
- `supabase_schema.sql` — fresh multi-module schema with RLS foundations
- `supabase_verification.sql` — post-reset schema/RLS verification

## Roles

Owner/Admin, Teacher, Student, Parent, Employee.

## Core V2 modules

Students/families, batches and fee plans, fee collection/accounting, attendance, staff/payroll/leave, exams/results, online learning/material, leads, reports, permissions and institute settings.

## Important database note

The reset SQL intentionally does not delete `auth.users`. Supabase Auth users must be managed through Supabase Auth administration. Existing project connectivity and email/SMTP configuration are not changed by the application schema scripts.

## Deployment

1. Backup any required legacy application data.
2. Run `supabase_fresh_reset.sql` against the intended VidyaDesk Supabase project.
3. Run `supabase_schema.sql`.
4. Run `supabase_verification.sql` and confirm expected tables, RLS and helper functions.
5. Configure the browser/client with the Supabase project URL and publishable key.
6. Build/sync Capacitor Android as required.

The database scripts are intentionally separate from the frontend so the GitHub deployment can update HTML/JS and SQL independently.
