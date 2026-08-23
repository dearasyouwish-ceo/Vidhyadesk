# VidyaDesk V2

VidyaDesk is a mobile-first coaching institute management platform for Indian academic and competitive-exam institutes.

## Architecture

- `www/index.html` — application entry point
- `www/app.js` — client application shell
- `www/*-workflow.js` — modular fee, attendance, exams, learning, portals, payroll, leads and notifications logic
- `supabase_fresh_reset.sql` — destructive legacy application-schema reset; does not touch Supabase Auth or SMTP/email configuration
- `supabase_schema.sql` — fresh multi-module schema with RLS foundations
- `supabase_verification.sql` — read-only post-reset verification

## Roles

Owner/Admin, Teacher, Student, Parent, Employee.

## Safe database migration

1. Back up any legacy application data that must be retained.
2. Run `supabase_fresh_reset.sql` only against the intended VidyaDesk project.
3. Run `supabase_schema.sql`.
4. Run `supabase_verification.sql`; confirm expected tables, RLS, helper routines and zero legacy application tables.
5. Configure the browser/client with the Supabase project URL and publishable key.
6. Build/sync Capacitor Android/iOS as required.

Existing Supabase Auth users are intentionally preserved. SMTP/email and project connectivity configuration are not changed by the application-schema scripts.

## Production boundaries

WhatsApp/SMS and biometric integrations require provider credentials/endpoints and should run server-side. The client only queues notification jobs and records attendance events; provider secrets must never be shipped in the mobile bundle.

## QA checklist

- Fresh schema applies cleanly.
- Verification reports no legacy application tables.
- RLS is enabled on tenant-owned tables.
- Owner/teacher/student/parent permissions are tested with separate Auth identities.
- Recurring fee generation is idempotent before production use.
- Payment totals cannot exceed bill balance.
- Print/PDF flows work inside Android/iOS WebView.
- Offline mutations are queued and replayed with conflict checks.
