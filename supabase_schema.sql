-- VidyaDesk NEW clean application schema
-- IMPORTANT: This file creates the new schema only. It does not modify Supabase project,
-- SMTP/email configuration, or Supabase internal auth tables.
-- Run supabase_fresh_reset.sql first on a database containing the old VidyaDesk schema.

begin;
create extension if not exists pgcrypto;

create table if not exists public.institutes (
  id uuid primary key default gen_random_uuid(), name text not null, logo_url text,
  owner_name text, phone text, whatsapp text, email text, address text, city text,
  state text, pincode text, website text, institute_type text not null default 'hybrid',
  academic_year text, gst_enabled boolean not null default false, gstin text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.institute_settings (
  institute_id uuid primary key references public.institutes(id) on delete cascade,
  currency text not null default 'INR', fee_cycle text not null default 'monthly',
  pro_rata_mode text not null default '30_day', reminder_day_1 int default 5,
  reminder_day_2 int default 10, dark_mode boolean not null default false,
  app_lock_enabled boolean not null default false, app_lock_pin_hash text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.institute_accounts (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null, account_type text not null check(account_type in ('cash','bank','upi','other')),
  bank_name text, account_number_masked text, ifsc text, opening_balance numeric(14,2) not null default 0,
  current_balance numeric(14,2) not null default 0, status text not null default 'active', created_at timestamptz not null default now()
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade, institute_id uuid references public.institutes(id) on delete cascade,
  role text not null default 'student' check(role in ('owner','admin','teacher','employee','student','parent')),
  full_name text not null, email text, mobile text, avatar_url text, status text not null default 'active',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  guardian_name text, guardian_mobile text, guardian_email text, address text, created_at timestamptz not null default now(),
  unique(institute_id, guardian_mobile)
);
create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade, student_id uuid not null,
  relationship text, primary key(family_id, student_id)
);
create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(), profile_id uuid references public.profiles(id) on delete set null,
  institute_id uuid not null references public.institutes(id) on delete cascade, full_name text not null,
  employee_code text, mobile text, email text, qualification text, subject text, address text, joining_date date,
  salary numeric(14,2) not null default 0, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(), profile_id uuid references public.profiles(id) on delete set null,
  institute_id uuid not null references public.institutes(id) on delete cascade, employee_code text, full_name text not null,
  mobile text, email text, role_title text, department text, joining_date date, salary numeric(14,2) not null default 0,
  bank_details jsonb not null default '{}'::jsonb, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(), profile_id uuid references public.profiles(id) on delete set null,
  institute_id uuid not null references public.institutes(id) on delete cascade, family_id uuid references public.families(id) on delete set null,
  student_code text, full_name text not null, father_name text, mother_name text, guardian_name text, mobile text, alternate_mobile text,
  email text, dob date, gender text, blood_group text, address text, school text, class_name text, board text,
  join_date date not null default current_date, leaving_date date, status text not null default 'active' check(status in ('active','inactive','completed','left','transferred')),
  photo_url text, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.student_documents (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade, document_type text not null, file_path text not null,
  file_name text, created_at timestamptz not null default now()
);
create table if not exists public.batches (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null, code text, organization_style text not null default 'class_wise' check(organization_style in ('class_wise','subject_wise','competitive')),
  class_name text, subject text, course_name text, duration text, teacher_id uuid references public.teachers(id) on delete set null,
  room text, capacity int, start_date date, end_date date, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.fee_plans (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete cascade, name text not null, basis text not null check(basis in ('monthly','quarterly','half_yearly','yearly','course')),
  amount numeric(14,2) not null default 0, installments_count int not null default 1, due_day int default 5,
  active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.batch_enrollments (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade, batch_id uuid not null references public.batches(id) on delete cascade,
  fee_plan_id uuid references public.fee_plans(id) on delete set null, discount_amount numeric(14,2) not null default 0,
  join_date date not null default current_date, end_date date, status text not null default 'active', created_at timestamptz not null default now(),
  unique(student_id,batch_id)
);
create table if not exists public.fee_bills (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete restrict, enrollment_id uuid references public.batch_enrollments(id) on delete set null,
  batch_id uuid references public.batches(id) on delete set null, fee_plan_id uuid references public.fee_plans(id) on delete set null,
  bill_number text not null, description text not null, period_start date, period_end date, due_date date,
  gross_amount numeric(14,2) not null default 0, discount_amount numeric(14,2) not null default 0,
  net_amount numeric(14,2) generated always as (gross_amount-discount_amount) stored,
  status text not null default 'pending' check(status in ('pending','partial','paid','void')), created_at timestamptz not null default now(),
  unique(institute_id,bill_number)
);
create table if not exists public.fee_items (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  bill_id uuid not null references public.fee_bills(id) on delete cascade, description text not null, amount numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.fee_discounts (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  bill_id uuid not null references public.fee_bills(id) on delete cascade, discount_type text not null, amount numeric(14,2) not null,
  reason text, approved_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.fee_installments (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  bill_id uuid not null references public.fee_bills(id) on delete cascade, installment_no int not null, due_date date, amount numeric(14,2) not null,
  paid_amount numeric(14,2) not null default 0, status text not null default 'pending', unique(bill_id,installment_no)
);
create table if not exists public.fee_payments (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  bill_id uuid not null references public.fee_bills(id) on delete restrict, account_id uuid references public.institute_accounts(id) on delete set null,
  amount numeric(14,2) not null check(amount>0), payment_mode text not null default 'cash', reference_no text, paid_at timestamptz not null default now(),
  received_by uuid references public.profiles(id) on delete set null, status text not null default 'posted', notes text, created_at timestamptz not null default now()
);
create table if not exists public.fee_receipts (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  payment_id uuid not null references public.fee_payments(id) on delete restrict, receipt_no text not null, pdf_path text,
  created_at timestamptz not null default now(), unique(institute_id,receipt_no)
);
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade, batch_id uuid references public.batches(id) on delete set null,
  attendance_date date not null, status text not null check(status in ('present','absent','late','leave')), marked_by uuid references public.profiles(id) on delete set null,
  source text not null default 'manual', punch_time timestamptz, note text, created_at timestamptz not null default now(), unique(student_id,attendance_date)
);
create table if not exists public.attendance_devices (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null, vendor text, ip_address text, port int, device_id text, status text not null default 'offline', last_sync_at timestamptz, config jsonb not null default '{}'::jsonb
);
create table if not exists public.attendance_logs (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  device_id uuid references public.attendance_devices(id) on delete set null, external_user_id text, punch_time timestamptz not null,
  raw_payload jsonb not null default '{}'::jsonb, processed boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.homework (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.teachers(id) on delete set null, batch_id uuid references public.batches(id) on delete set null,
  title text not null, description text, due_date date, attachment_path text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.diary_entries (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.teachers(id) on delete set null, batch_id uuid references public.batches(id) on delete set null,
  entry_date date not null default current_date, title text, body text, attachment_path text, created_at timestamptz not null default now()
);
create table if not exists public.study_materials (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete set null, subject text, title text not null, material_type text not null default 'pdf',
  url text, storage_path text, created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  title text not null, body text not null, audience text not null default 'all', publish_at timestamptz default now(), created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  title text not null, description text, cover_path text, status text not null default 'draft', created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.course_sections (
  id uuid primary key default gen_random_uuid(), course_id uuid not null references public.courses(id) on delete cascade, title text not null, position int not null default 0
);
create table if not exists public.course_lessons (
  id uuid primary key default gen_random_uuid(), section_id uuid not null references public.course_sections(id) on delete cascade,
  title text not null, lesson_type text not null default 'video', video_url text, pdf_path text, body text, position int not null default 0
);
create table if not exists public.course_enrollments (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade, student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(), unique(course_id,student_id)
);
create table if not exists public.course_progress (
  id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.course_lessons(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade, completed boolean not null default false, progress_percent numeric(5,2) not null default 0,
  last_position_seconds int not null default 0, updated_at timestamptz not null default now(), unique(lesson_id,student_id)
);
create table if not exists public.course_notes (
  id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.course_lessons(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade, note text not null, created_at timestamptz not null default now()
);
create table if not exists public.course_bookmarks (
  id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.course_lessons(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade, created_at timestamptz not null default now(), unique(lesson_id,student_id)
);
create table if not exists public.course_discussions (
  id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.course_lessons(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade, body text not null, created_at timestamptz not null default now()
);
create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  title text not null, description text, batch_id uuid references public.batches(id) on delete set null, teacher_id uuid references public.teachers(id) on delete set null,
  duration_minutes int default 30, pass_percent numeric(6,2) default 35, start_at timestamptz, end_at timestamptz, status text not null default 'draft', created_at timestamptz not null default now()
);
create table if not exists public.exam_questions (
  id uuid primary key default gen_random_uuid(), exam_id uuid not null references public.exams(id) on delete cascade,
  question_text text not null, option_a text, option_b text, option_c text, option_d text, correct_option text, marks numeric(10,2) not null default 1, position int not null default 0
);
create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade, student_id uuid not null references public.students(id) on delete cascade,
  score numeric(12,2) not null default 0, total_marks numeric(12,2) not null default 0, percentage numeric(7,2) not null default 0,
  status text not null default 'submitted', started_at timestamptz default now(), submitted_at timestamptz, unique(exam_id,student_id)
);
create table if not exists public.exam_answers (
  id uuid primary key default gen_random_uuid(), attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  question_id uuid not null references public.exam_questions(id) on delete cascade, selected_option text, is_correct boolean, marks_awarded numeric(12,2) default 0,
  unique(attempt_id,question_id)
);
create table if not exists public.exam_marks (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade, student_id uuid not null references public.students(id) on delete cascade,
  subject text, marks numeric(10,2) not null default 0, max_marks numeric(10,2) not null default 100, grade text, created_at timestamptz not null default now(), unique(exam_id,student_id,subject)
);
create table if not exists public.results (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade, student_id uuid not null references public.students(id) on delete cascade,
  total_marks numeric(12,2) not null default 0, max_marks numeric(12,2) not null default 0, percentage numeric(7,2) not null default 0, grade text, result_status text, pdf_path text,
  created_at timestamptz not null default now(), unique(exam_id,student_id)
);
create table if not exists public.timetables (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete set null,
  weekday int not null check(weekday between 1 and 7), start_time time not null, end_time time not null, subject text, room text, created_at timestamptz not null default now()
);
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null, mobile text, email text, course_interested text, source text, status text not null default 'new', notes text, assigned_to uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.lead_followups (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade, due_at timestamptz not null, notes text, status text not null default 'open', created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.expense_categories (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade, name text not null, unique(institute_id,name)
);
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  account_id uuid references public.institute_accounts(id) on delete set null, category_id uuid references public.expense_categories(id) on delete set null,
  amount numeric(14,2) not null check(amount>0), description text, expense_date date not null default current_date, payment_mode text, created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.payroll (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  employee_id uuid references public.employees(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete cascade,
  salary_month date not null, gross_amount numeric(14,2) not null default 0, deduction numeric(14,2) not null default 0, paid_amount numeric(14,2) not null default 0,
  status text not null default 'pending', payment_mode text, paid_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  employee_id uuid references public.employees(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete cascade,
  from_date date not null, to_date date not null, reason text, status text not null default 'pending', approved_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.user_permissions (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade, feature text not null, allowed boolean not null default false, unique(user_id,feature)
);
create table if not exists public.batch_permissions (
  user_id uuid not null references public.profiles(id) on delete cascade, batch_id uuid not null references public.batches(id) on delete cascade, primary key(user_id,batch_id)
);
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade, title text not null, body text not null, type text, read_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.notification_logs (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  channel text not null, recipient text, template text, payload jsonb not null default '{}'::jsonb, status text, provider_message_id text, sent_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(), institute_id uuid references public.institutes(id) on delete cascade, actor_id uuid references public.profiles(id) on delete set null,
  action text not null, table_name text, record_id uuid, old_data jsonb, new_data jsonb, created_at timestamptz not null default now()
);
create table if not exists public.backup_records (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade, backup_type text not null,
  storage_path text, status text not null default 'created', created_at timestamptz not null default now()
);

create index if not exists idx_students_institute on public.students(institute_id);
create index if not exists idx_batches_institute on public.batches(institute_id);
create index if not exists idx_enrollments_student on public.batch_enrollments(student_id);
create index if not exists idx_bills_student on public.fee_bills(student_id);
create index if not exists idx_bills_due on public.fee_bills(institute_id,due_date,status);
create index if not exists idx_payments_date on public.fee_payments(institute_id,paid_at);
create index if not exists idx_attendance_date on public.attendance(institute_id,attendance_date);
create index if not exists idx_leads_followup on public.lead_followups(institute_id,due_at,status);
create index if not exists idx_activity_logs on public.activity_logs(institute_id,created_at);

create or replace function public.vd_set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;

drop trigger if exists trg_institutes_updated on public.institutes; create trigger trg_institutes_updated before update on public.institutes for each row execute function public.vd_set_updated_at();
drop trigger if exists trg_profiles_updated on public.profiles; create trigger trg_profiles_updated before update on public.profiles for each row execute function public.vd_set_updated_at();
drop trigger if exists trg_students_updated on public.students; create trigger trg_students_updated before update on public.students for each row execute function public.vd_set_updated_at();
drop trigger if exists trg_batches_updated on public.batches; create trigger trg_batches_updated before update on public.batches for each row execute function public.vd_set_updated_at();
drop trigger if exists trg_teachers_updated on public.teachers; create trigger trg_teachers_updated before update on public.teachers for each row execute function public.vd_set_updated_at();
drop trigger if exists trg_courses_updated on public.courses; create trigger trg_courses_updated before update on public.courses for each row execute function public.vd_set_updated_at();
drop trigger if exists trg_leads_updated on public.leads; create trigger trg_leads_updated before update on public.leads for each row execute function public.vd_set_updated_at();

create or replace function public.vd_my_institute_id() returns uuid language sql stable security definer set search_path=public as $$ select institute_id from public.profiles where id=auth.uid() $$;
create or replace function public.vd_is_owner() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin') and status='active') $$;

alter table public.institutes enable row level security;
alter table public.institute_settings enable row level security;
alter table public.institute_accounts enable row level security;
alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.teachers enable row level security;
alter table public.employees enable row level security;
alter table public.students enable row level security;
alter table public.student_documents enable row level security;
alter table public.batches enable row level security;
alter table public.fee_plans enable row level security;
alter table public.batch_enrollments enable row level security;
alter table public.fee_bills enable row level security;
alter table public.fee_items enable row level security;
alter table public.fee_discounts enable row level security;
alter table public.fee_installments enable row level security;
alter table public.fee_payments enable row level security;
alter table public.fee_receipts enable row level security;
alter table public.attendance enable row level security;
alter table public.attendance_devices enable row level security;
alter table public.attendance_logs enable row level security;
alter table public.homework enable row level security;
alter table public.diary_entries enable row level security;
alter table public.study_materials enable row level security;
alter table public.notices enable row level security;
alter table public.courses enable row level security;
alter table public.course_sections enable row level security;
alter table public.course_lessons enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.course_progress enable row level security;
alter table public.course_notes enable row level security;
alter table public.course_bookmarks enable row level security;
alter table public.course_discussions enable row level security;
alter table public.exams enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.exam_answers enable row level security;
alter table public.exam_marks enable row level security;
alter table public.results enable row level security;
alter table public.timetables enable row level security;
alter table public.leads enable row level security;
alter table public.lead_followups enable row level security;
alter table public.expense_categories enable row level security;
alter table public.expenses enable row level security;
alter table public.payroll enable row level security;
alter table public.leave_requests enable row level security;
alter table public.user_permissions enable row level security;
alter table public.batch_permissions enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_logs enable row level security;
alter table public.activity_logs enable row level security;
alter table public.backup_records enable row level security;

-- Generic institute isolation policies. Owner/admin gets write access; other roles get read access where appropriate.
do $$ declare t text; begin
  foreach t in array array['institute_settings','institute_accounts','families','family_members','teachers','employees','students','student_documents','batches','fee_plans','batch_enrollments','fee_bills','fee_items','fee_discounts','fee_installments','fee_payments','fee_receipts','attendance','attendance_devices','attendance_logs','homework','diary_entries','study_materials','notices','courses','course_sections','course_lessons','course_enrollments','course_progress','course_notes','course_bookmarks','course_discussions','exams','exam_questions','exam_attempts','exam_answers','exam_marks','results','timetables','leads','lead_followups','expense_categories','expenses','payroll','leave_requests','user_permissions','batch_permissions','notifications','notification_logs','activity_logs','backup_records'] loop
    execute format('drop policy if exists vd_select on public.%I',t);
    execute format('create policy vd_select on public.%I for select using (institute_id = public.vd_my_institute_id())',t);
    execute format('drop policy if exists vd_owner_write on public.%I',t);
    execute format('create policy vd_owner_write on public.%I for all using (public.vd_is_owner() and institute_id = public.vd_my_institute_id()) with check (public.vd_is_owner() and institute_id = public.vd_my_institute_id())',t);
  end loop;
end $$;

-- Tables without a direct institute_id use related records and are restricted through owner or relationship policies below.
drop policy if exists vd_profiles_select on public.profiles;
create policy vd_profiles_select on public.profiles for select using (id=auth.uid() or institute_id=public.vd_my_institute_id());
drop policy if exists vd_profiles_owner on public.profiles;
create policy vd_profiles_owner on public.profiles for all using (public.vd_is_owner() and institute_id=public.vd_my_institute_id()) with check (public.vd_is_owner() and institute_id=public.vd_my_institute_id());
drop policy if exists vd_institutes_select on public.institutes;
create policy vd_institutes_select on public.institutes for select using (id=public.vd_my_institute_id());
drop policy if exists vd_institutes_owner on public.institutes;
create policy vd_institutes_owner on public.institutes for all using (public.vd_is_owner() and id=public.vd_my_institute_id()) with check (public.vd_is_owner() and id=public.vd_my_institute_id());

commit;
