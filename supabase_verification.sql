-- VidyaDesk post-reset verification
-- Run after supabase_fresh_reset.sql + supabase_schema.sql.

select 'NEW TABLES' as check_group, count(*) as count
from information_schema.tables
where table_schema='public'
and table_name in ('institutes','institute_settings','institute_accounts','profiles','families','family_members','teachers','employees','students','student_documents','batches','batch_enrollments','fee_plans','fee_bills','fee_items','fee_payments','fee_installments','fee_discounts','fee_receipts','attendance','attendance_devices','attendance_logs','homework','diary_entries','study_materials','notices','courses','course_sections','course_lessons','course_enrollments','course_progress','course_notes','course_bookmarks','course_discussions','exams','exam_questions','exam_attempts','exam_answers','exam_marks','results','timetables','leads','lead_followups','expense_categories','expenses','payroll','leave_requests','user_permissions','batch_permissions','notifications','notification_logs','activity_logs','backup_records');

select tablename, rowsecurity as rls_enabled
from pg_tables
where schemaname='public'
and tablename in ('institutes','institute_settings','institute_accounts','profiles','students','batches','fee_bills','fee_payments','attendance','courses','exams','leads','expenses','payroll','notifications','activity_logs')
order by tablename;

select routine_name
from information_schema.routines
where routine_schema='public' and routine_name in ('vd_my_institute_id','vd_is_owner','vd_set_updated_at')
order by routine_name;

select table_name, count(*) as policy_count
from information_schema.tables t
left join pg_policies p on p.schemaname=t.table_schema and p.tablename=t.table_name
where t.table_schema='public'
and t.table_name in ('institutes','profiles','students','batches','fee_bills','fee_payments','attendance','courses','exams','leads','expenses','payroll','notifications')
group by table_name
order by table_name;

-- Legacy table check: should return zero rows for the listed V1 names.
select table_name as legacy_table_found
from information_schema.tables
where table_schema='public'
and table_name in ('classes','class_memberships','class_join_requests','vd_legacy_profiles','vd_legacy_classes','vd_legacy_class_memberships','vd_legacy_class_join_requests','vd_legacy_homework','vd_legacy_materials','vd_legacy_notices');

-- Supabase Auth connectivity is deliberately NOT inspected or modified here.
-- SMTP/email/project configuration is deliberately NOT inspected or modified here.
