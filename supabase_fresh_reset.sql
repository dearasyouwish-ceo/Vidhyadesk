-- VIDYADESK FRESH DATABASE RESET
-- DESTRUCTIVE: removes OLD VidyaDesk application objects/data.
-- PRESERVES: Supabase project connectivity, SMTP/email configuration, project URL/API,
-- and Supabase internal auth infrastructure. Do NOT run against unrelated schemas.
-- IMPORTANT: old auth.users must be removed through Supabase Auth Admin tooling if desired;
-- this SQL intentionally does NOT delete or alter auth.users.

begin;

create extension if not exists pgcrypto;

-- Drop old VidyaDesk application schema objects. CASCADE removes legacy app policies,
-- constraints and dependent application objects. Supabase system schemas are untouched.
drop table if exists public.exam_answers cascade;
drop table if exists public.exam_attempts cascade;
drop table if exists public.exam_questions cascade;
drop table if exists public.exams cascade;
drop table if exists public.course_discussions cascade;
drop table if exists public.course_bookmarks cascade;
drop table if exists public.course_notes cascade;
drop table if exists public.course_progress cascade;
drop table if exists public.course_enrollments cascade;
drop table if exists public.course_lessons cascade;
drop table if exists public.course_sections cascade;
drop table if exists public.courses cascade;
drop table if exists public.study_materials cascade;
drop table if exists public.diary_entries cascade;
drop table if exists public.homework cascade;
drop table if exists public.attendance_logs cascade;
drop table if exists public.attendance_devices cascade;
drop table if exists public.attendance cascade;
drop table if exists public.fee_receipts cascade;
drop table if exists public.fee_payments cascade;
drop table if exists public.fee_installments cascade;
drop table if exists public.fee_discounts cascade;
drop table if exists public.fee_items cascade;
drop table if exists public.fee_bills cascade;
drop table if exists public.batch_enrollments cascade;
drop table if exists public.fee_plans cascade;
drop table if exists public.batches cascade;
drop table if exists public.student_documents cascade;
drop table if exists public.students cascade;
drop table if exists public.family_members cascade;
drop table if exists public.families cascade;
drop table if exists public.teachers cascade;
drop table if exists public.employees cascade;
drop table if exists public.lead_followups cascade;
drop table if exists public.leads cascade;
drop table if exists public.timetables cascade;
drop table if exists public.expenses cascade;
drop table if exists public.expense_categories cascade;
drop table if exists public.payroll cascade;
drop table if exists public.leave_requests cascade;
drop table if exists public.user_permissions cascade;
drop table if exists public.batch_permissions cascade;
drop table if exists public.notifications cascade;
drop table if exists public.notification_logs cascade;
drop table if exists public.activity_logs cascade;
drop table if exists public.backup_records cascade;
drop table if exists public.institute_accounts cascade;
drop table if exists public.institute_settings cascade;
drop table if exists public.profiles cascade;
drop table if exists public.institutes cascade;

-- Remove old application-specific helper functions/types only.
drop function if exists public.vd_my_institute_id() cascade;
drop function if exists public.vd_is_owner() cascade;
drop function if exists public.vd_set_updated_at() cascade;
drop type if exists public.user_role cascade;

-- Remove known legacy VidyaDesk V1 tables if they still exist.
drop table if exists public.vd_legacy_profiles cascade;
drop table if exists public.vd_legacy_classes cascade;
drop table if exists public.vd_legacy_class_memberships cascade;
drop table if exists public.vd_legacy_class_join_requests cascade;
drop table if exists public.vd_legacy_homework cascade;
drop table if exists public.vd_legacy_materials cascade;
drop table if exists public.vd_legacy_notices cascade;
drop table if exists public.classes cascade;
drop table if exists public.class_memberships cascade;
drop table if exists public.class_join_requests cascade;

-- Apply the clean NEW schema.
-- This statement is intentionally kept as an instruction for the Supabase SQL Editor:
-- run this file followed by supabase_schema.sql in the same SQL session.

commit;

-- NEXT STEP:
-- Execute supabase_schema.sql immediately after this reset script.
-- Do not modify SMTP/email/project connectivity as part of this reset.
