-- VidyaDesk V2 (FIXED) — one-time migration from the current VidyaDesk V1 schema.
-- Keeps existing Auth user IDs and current profile users, then replaces the old class model
-- with Admin + Teacher + Student + Batch + Fees + Attendance + Homework + Notices + Material
-- + Online Courses + Online Exams + Leads + Timetable.
-- Run this in Supabase SQL Editor for the VidyaDesk project.
--
-- Changes vs. the uploaded vidyadesk_supabase_v2.sql — search this file for "FIX" to see each one inline:
--  1) "institute bootstrap insert" checked whether ANY admin existed anywhere in the whole database.
--     After your first institute signed up, no second institute could ever be created. Now scoped to
--     "this user doesn't already belong to an institute", so onboarding works for every new customer.
--  2) "profiles self update" let any signed-in user UPDATE THEIR OWN role/institute_id/status directly
--     (e.g. `update profiles set role='admin', institute_id='<any id>'`) — a full privilege-escalation
--     hole. Now self-updates cannot change role/status/institute_id; a new security-definer trigger
--     (handle_new_institute) promotes an institute's creator to admin atomically instead.
--  3) "students own update" had the same gap for a student's own row (institute_id/batch_id/status).
--     Now those three columns must stay unchanged on a student's self-update.

begin;
create extension if not exists pgcrypto;

-- 1) Preserve the current V1 tables under legacy names during migration.
alter table if exists public.profiles rename to vd_legacy_profiles;
alter table if exists public.classes rename to vd_legacy_classes;
alter table if exists public.class_memberships rename to vd_legacy_class_memberships;
alter table if exists public.class_join_requests rename to vd_legacy_class_join_requests;
alter table if exists public.homework rename to vd_legacy_homework;
alter table if exists public.materials rename to vd_legacy_materials;
alter table if exists public.notices rename to vd_legacy_notices;

-- Recreate the application tables from the new model.
DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('admin','teacher','student');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

drop table if exists public.exam_answers cascade;
drop table if exists public.exam_attempts cascade;
drop table if exists public.exam_questions cascade;
drop table if exists public.exams cascade;
drop table if exists public.course_lessons cascade;
drop table if exists public.course_sections cascade;
drop table if exists public.courses cascade;
drop table if exists public.study_materials cascade;
drop table if exists public.notices cascade;
drop table if exists public.homework cascade;
drop table if exists public.attendance cascade;
drop table if exists public.fees cascade;
drop table if exists public.leads cascade;
drop table if exists public.timetables cascade;
drop table if exists public.batches cascade;
drop table if exists public.students cascade;
drop table if exists public.teachers cascade;
drop table if exists public.profiles cascade;
drop table if exists public.institutes cascade;

create table public.institutes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  institute_type text default 'Academic',
  country text default 'India',
  state text,
  city text,
  address text,
  mobile text,
  email text,
  logo_url text,
  owner_profile_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  institute_id uuid references public.institutes(id) on delete cascade,
  role public.user_role not null default 'student',
  full_name text not null,
  email text,
  login_id text,
  mobile text,
  avatar_url text,
  status text not null default 'pending' check (status in ('active','inactive','pending')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (institute_id, login_id)
);

alter table public.institutes
  add constraint institutes_owner_fk foreign key (owner_profile_id) references public.profiles(id) on delete set null;

create table public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  institute_id uuid not null references public.institutes(id) on delete cascade,
  full_name text not null,
  employee_code text,
  mobile text,
  subject text,
  qualification text,
  address text,
  joining_date date,
  status text not null default 'active' check (status in ('active','inactive')),
  permissions jsonb not null default '{"batches":true,"homework":true,"materials":true,"courses":true,"exams":true,"notices":true}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.batches (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete set null,
  name text not null,
  course_name text,
  schedule text,
  monthly_fee numeric(12,2) not null default 0,
  room text,
  status text not null default 'active' check (status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete set null,
  full_name text not null,
  student_code text,
  guardian_name text,
  mobile text,
  address text,
  dob date,
  gender text,
  blood_group text,
  join_date date default current_date,
  status text not null default 'active' check (status in ('active','inactive')),
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.fees (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  student_name text,
  batch_id uuid references public.batches(id) on delete set null,
  fee_month text not null,
  amount_due numeric(12,2) not null default 0,
  amount_paid numeric(12,2) not null default 0,
  payment_mode text default 'Cash',
  status text not null default 'pending' check (status in ('pending','partial','paid','cancelled')),
  receipt_no text,
  notes text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete set null,
  date date not null,
  status text not null check (status in ('present','absent','late','leave')),
  marked_by uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  unique(student_id,date)
);

create table public.homework (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete set null,
  student_id uuid references public.profiles(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete set null,
  title text not null,
  description text,
  attachment_url text,
  due_date date,
  status text default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notices (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete set null,
  title text not null,
  body text not null,
  audience text not null default 'all' check (audience in ('all','teachers','students','parents')),
  publish_at timestamptz default now(),
  created_at timestamptz not null default now()
);

create table public.study_materials (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete set null,
  student_id uuid references public.profiles(id) on delete set null,
  batch_id uuid references public.batches(id) on delete set null,
  title text not null,
  description text,
  material_type text not null default 'PDF',
  file_url text,
  created_at timestamptz not null default now()
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  cover_url text,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.course_sections (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table public.course_lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  section_id uuid references public.course_sections(id) on delete cascade,
  title text not null,
  lesson_type text not null default 'Video',
  content_url text,
  notes text,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  pass_percent numeric(5,2) default 35,
  duration_minutes int default 30,
  status text not null default 'draft' check (status in ('draft','published','closed')),
  start_at timestamptz,
  end_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.exam_questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  question_text text not null,
  option_a text,
  option_b text,
  option_c text,
  option_d text,
  correct_option text check (correct_option in ('option_a','option_b','option_c','option_d')),
  marks numeric(8,2) not null default 1,
  position int not null default 0
);

create table public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  score numeric(10,2) default 0,
  total_marks numeric(10,2) default 0,
  percentage numeric(6,2) default 0,
  status text not null default 'submitted',
  started_at timestamptz default now(),
  submitted_at timestamptz
);

create table public.exam_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  question_id uuid not null references public.exam_questions(id) on delete cascade,
  selected_option text,
  is_correct boolean,
  marks_awarded numeric(10,2) default 0,
  unique(attempt_id,question_id)
);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null,
  mobile text,
  email text,
  source text default 'Walk-in',
  course_interested text,
  note text,
  status text not null default 'new' check (status in ('new','contacted','converted','lost')),
  created_at timestamptz not null default now()
);

create table public.timetables (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete set null,
  batch_name text,
  weekday int not null default 1 check (weekday between 1 and 7),
  start_time time,
  end_time time,
  subject text,
  room text,
  teacher_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- 2) Build one institute for the existing V1 project and preserve current users.
create temp table vd_bootstrap_institute(id uuid);
insert into vd_bootstrap_institute values(gen_random_uuid());
insert into public.institutes(id,name,institute_type,country,state,city)
select id,'VidyaDesk Institute','Academic','India',null,null from vd_bootstrap_institute;

-- The first existing tutor becomes Admin; additional tutors become Teacher; students stay Student.
insert into public.profiles(id,institute_id,role,full_name,email,login_id,mobile,status,created_at)
select
  lp.id,
  bi.id,
  case
    when lp.role='tutor' and row_number() over (partition by lp.role order by lp.created_at,lp.id)=1 then 'admin'::public.user_role
    when lp.role='tutor' then 'teacher'::public.user_role
    when lp.role='student' then 'student'::public.user_role
    else 'student'::public.user_role
  end,
  lp.full_name,
  au.email,
  lower(coalesce(split_part(au.email,'@',1),left(lp.id::text,8))),
  lp.phone,
  'active',
  lp.created_at
from public.vd_legacy_profiles lp
cross join vd_bootstrap_institute bi
left join auth.users au on au.id=lp.id;

update public.institutes i
set owner_profile_id=p.id
from public.profiles p
where i.id=(select id from vd_bootstrap_institute)
  and p.role='admin'
  and p.institute_id=i.id
  and not exists(select 1 from public.institutes where owner_profile_id=p.id);

-- 3) Teachers.
insert into public.teachers(profile_id,institute_id,full_name,employee_code,mobile,status,created_at)
select p.id,p.institute_id,p.full_name,'TEA-'||left(replace(p.id::text,'-',''),7),p.mobile,'active',p.created_at
from public.profiles p
where p.role='teacher';

-- 4) Convert legacy classes into batches.
create temp table vd_batch_map(legacy_class_id text primary key,new_batch_id uuid);
with moved as (
  insert into public.batches(institute_id,teacher_id,name,course_name,schedule,status,created_at)
  select
    (select id from vd_bootstrap_institute),
    case when p.role in ('admin','teacher') then p.id else null end,
    c.name,
    c.subject,
    c.description,
    'active',
    to_timestamp(c.created_at/1000.0)
  from public.vd_legacy_classes c
  left join public.profiles p on p.id=coalesce(c.owner_uid,c.owner_id)
  returning id, name
)
select null::text as legacy_class_id, id as new_batch_id into temp vd_tmp_empty from moved limit 0;

insert into vd_batch_map(legacy_class_id,new_batch_id)
select c.id,m.id
from public.vd_legacy_classes c
join public.batches m on m.institute_id=(select id from vd_bootstrap_institute) and m.name=c.name
  and coalesce(m.course_name,'')=coalesce(c.subject,'')
  and m.created_at=to_timestamp(c.created_at/1000.0);

drop table vd_tmp_empty;

-- 5) Students from existing Auth-linked profiles.
insert into public.students(profile_id,institute_id,batch_id,full_name,student_code,mobile,join_date,status)
select
  p.id,
  p.institute_id,
  bm.new_batch_id,
  p.full_name,
  'STU-'||left(replace(p.id::text,'-',''),7),
  p.mobile,
  p.created_at::date,
  'active'
from public.profiles p
left join lateral (
  select cm.class_id
  from public.vd_legacy_class_memberships cm
  where cm.student_id=p.id
  order by cm.approved_at
  limit 1
) cm on true
left join vd_batch_map bm on bm.legacy_class_id=cm.class_id
where p.role='student';

-- Preserve class memberships for any student who did not have a V1 profile yet by creating
-- a profile row only when the referenced Auth user exists.
insert into public.profiles(id,institute_id,role,full_name,mobile,status)
select distinct cm.student_id,(select id from vd_bootstrap_institute),'student'::public.user_role,cm.student_name,cm.student_phone,'active'
from public.vd_legacy_class_memberships cm
left join public.profiles p on p.id=cm.student_id
where p.id is null and exists(select 1 from auth.users au where au.id=cm.student_id);

insert into public.students(profile_id,institute_id,batch_id,full_name,student_code,mobile,join_date,status)
select
  p.id,p.institute_id,bm.new_batch_id,p.full_name,
  'STU-'||left(replace(p.id::text,'-',''),7),p.mobile,current_date,'active'
from public.profiles p
join (select distinct on (student_id) student_id,class_id from public.vd_legacy_class_memberships order by student_id,approved_at) cm
  on cm.student_id=p.id
left join vd_batch_map bm on bm.legacy_class_id=cm.class_id
where p.role='student'
  and not exists(select 1 from public.students s where s.profile_id=p.id);

-- 6) Migrate V1 homework/materials/notices, keeping the new tenant/batch model.
insert into public.homework(institute_id,teacher_id,batch_id,title,description,created_at)
select
  (select id from vd_bootstrap_institute),
  b.teacher_id,
  bm.new_batch_id,
  h.title,
  h.body,
  h.created_at
from public.vd_legacy_homework h
join vd_batch_map bm on bm.legacy_class_id=h.class_id
join public.batches b on b.id=bm.new_batch_id;

insert into public.study_materials(institute_id,batch_id,title,description,material_type,file_url,created_at)
select
  (select id from vd_bootstrap_institute),
  bm.new_batch_id,
  m.title,
  m.body,
  case when m.link is not null and m.link<>'' then 'Link' else 'Note' end,
  nullif(m.link,''),
  m.created_at
from public.vd_legacy_materials m
join vd_batch_map bm on bm.legacy_class_id=m.class_id;

insert into public.notices(institute_id,title,body,audience,created_at)
select (select id from vd_bootstrap_institute),n.title,n.body,'all',n.created_at
from public.vd_legacy_notices n;

-- 7) RLS helper functions.
create schema if not exists private;
create or replace function private.current_role()
returns text language sql stable security definer set search_path=public,pg_temp
as $$ select p.role::text from public.profiles p where p.id=auth.uid() $$;
create or replace function private.current_institute()
returns uuid language sql stable security definer set search_path=public,pg_temp
as $$ select p.institute_id from public.profiles p where p.id=auth.uid() $$;
grant execute on function private.current_role() to authenticated;
grant execute on function private.current_institute() to authenticated;

-- 8) New-user trigger. First-time users are pending Students until Admin assigns them.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  insert into public.profiles(id,full_name,email,login_id,role,status)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',split_part(coalesce(new.email,''),'@',1),'User'),new.email,lower(split_part(coalesce(new.email,''),'@',1)),'student','pending')
  on conflict(id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- FIX / NEW: with self-escalation now blocked (see "profiles self update" above), the user who creates
-- an institute needs a trusted, atomic way to become its admin. This trigger runs as security definer
-- immediately after a new institute row is inserted (owner_profile_id already required to be the caller
-- by the "institute bootstrap insert" policy) and promotes that one profile to admin/active/institute_id.
create or replace function public.handle_new_institute()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.owner_profile_id is not null then
    update public.profiles
    set institute_id = new.id, role = 'admin', status = 'active'
    where id = new.owner_profile_id;
  end if;
  return new;
end;
$$;
drop trigger if exists on_institute_created on public.institutes;
create trigger on_institute_created after insert on public.institutes for each row execute procedure public.handle_new_institute();

-- 9) Prevent ordinary users from changing role/tenant, while allowing first-account bootstrap.
-- 10) RLS.
alter table public.institutes enable row level security;
alter table public.profiles enable row level security;
alter table public.teachers enable row level security;
alter table public.batches enable row level security;
alter table public.students enable row level security;
alter table public.fees enable row level security;
alter table public.attendance enable row level security;
alter table public.homework enable row level security;
alter table public.notices enable row level security;
alter table public.study_materials enable row level security;
alter table public.courses enable row level security;
alter table public.course_sections enable row level security;
alter table public.course_lessons enable row level security;
alter table public.exams enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.exam_answers enable row level security;
alter table public.leads enable row level security;
alter table public.timetables enable row level security;

create policy "institute select" on public.institutes for select to authenticated using (id=private.current_institute());
-- FIX (was a global check "no admin exists anywhere" — that blocks every institute after the very
-- first one signs up, which breaks multi-institute onboarding). Now scoped per-user: an authenticated
-- user may create an institute only while they don't already belong to one, and only as its owner.
create policy "institute bootstrap insert" on public.institutes for insert to authenticated with check (
  owner_profile_id = auth.uid()
  and not exists (select 1 from public.profiles p where p.id = auth.uid() and p.institute_id is not null)
);
create policy "institute admin update" on public.institutes for update to authenticated using (id=private.current_institute() and private.current_role()='admin') with check (id=private.current_institute() and private.current_role()='admin');

create policy "profiles self or admin select" on public.profiles for select to authenticated using (id=auth.uid() or (institute_id=private.current_institute() and private.current_role()='admin'));
-- FIX (was `using(id=auth.uid()) with check(id=auth.uid())` with no column restriction — that let any
-- signed-in user set their OWN role to 'admin' and institute_id to ANY institute via a plain UPDATE,
-- a full privilege-escalation hole). Ordinary users may now only update their own profile when role,
-- institute_id and status stay unchanged; role/tenant changes still require the admin policy below or
-- the institute-creation trigger (which runs as security definer).
create policy "profiles self update" on public.profiles for update to authenticated using (id=auth.uid()) with check (
  id=auth.uid()
  and role = (select role from public.profiles where id=auth.uid())
  and status = (select status from public.profiles where id=auth.uid())
  and institute_id is not distinct from (select institute_id from public.profiles where id=auth.uid())
);
create policy "profiles admin update" on public.profiles for update to authenticated using (institute_id=private.current_institute() and private.current_role()='admin') with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "profiles admin insert" on public.profiles for insert to authenticated with check (private.current_role()='admin');

create policy "teachers tenant select" on public.teachers for select to authenticated using (institute_id=private.current_institute());
create policy "teachers admin insert" on public.teachers for insert to authenticated with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "teachers admin update" on public.teachers for update to authenticated using (institute_id=private.current_institute() and private.current_role()='admin') with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "teachers admin delete" on public.teachers for delete to authenticated using (institute_id=private.current_institute() and private.current_role()='admin');

create policy "batches tenant select" on public.batches for select to authenticated using (institute_id=private.current_institute());
create policy "batches admin insert" on public.batches for insert to authenticated with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "batches admin update" on public.batches for update to authenticated using (institute_id=private.current_institute() and private.current_role()='admin') with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "batches admin delete" on public.batches for delete to authenticated using (institute_id=private.current_institute() and private.current_role()='admin');

create policy "students select by role" on public.students for select to authenticated using (
  institute_id=private.current_institute() and (
    private.current_role()='admin' or profile_id=auth.uid() or
    (private.current_role()='teacher' and batch_id in(select id from public.batches where teacher_id=auth.uid()))
  )
);
create policy "students admin insert" on public.students for insert to authenticated with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "students admin update" on public.students for update to authenticated using (institute_id=private.current_institute() and private.current_role()='admin') with check (institute_id=private.current_institute() and private.current_role()='admin');
-- FIX (was `using(profile_id=auth.uid()) with check(profile_id=auth.uid())` with no other restriction —
-- a student could update their OWN students row to change institute_id, batch_id or status, e.g. move
-- themselves into another institute's data or self-enroll into any batch). Now a student may only touch
-- their own row, and institute_id/batch_id/status must stay exactly as they were.
create policy "students own update" on public.students for update to authenticated using(profile_id=auth.uid()) with check(
  profile_id=auth.uid()
  and institute_id = (select institute_id from public.students where profile_id=auth.uid())
  and batch_id is not distinct from (select batch_id from public.students where profile_id=auth.uid())
  and status = (select status from public.students where profile_id=auth.uid())
);
create policy "students admin delete" on public.students for delete to authenticated using(institute_id=private.current_institute() and private.current_role()='admin');

create policy "fees select by role" on public.fees for select to authenticated using (
  institute_id=private.current_institute() and (
    private.current_role()='admin' or student_id in(select id from public.students where profile_id=auth.uid()) or
    (private.current_role()='teacher' and batch_id in(select id from public.batches where teacher_id=auth.uid()))
  )
);
create policy "fees admin insert" on public.fees for insert to authenticated with check (institute_id=private.current_institute() and private.current_role()='admin');
create policy "fees admin update" on public.fees for update to authenticated using(institute_id=private.current_institute() and private.current_role()='admin') with check(institute_id=private.current_institute() and private.current_role()='admin');

create policy "attendance select" on public.attendance for select to authenticated using (
  institute_id=private.current_institute() and (
    private.current_role()='admin' or student_id in(select id from public.students where profile_id=auth.uid()) or batch_id in(select id from public.batches where teacher_id=auth.uid())
  )
);
create policy "attendance staff insert" on public.attendance for insert to authenticated with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));
create policy "attendance staff update" on public.attendance for update to authenticated using(institute_id=private.current_institute() and private.current_role() in ('admin','teacher')) with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));

create policy "homework select" on public.homework for select to authenticated using (
  institute_id=private.current_institute() and (
    private.current_role()='admin' or teacher_id=auth.uid() or student_id=auth.uid() or
    (private.current_role()='student' and batch_id in(select s.batch_id from public.students s where s.profile_id=auth.uid())) or
    (private.current_role()='teacher' and batch_id in(select id from public.batches where teacher_id=auth.uid()))
  )
);
create policy "homework staff insert" on public.homework for insert to authenticated with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));
create policy "homework staff update" on public.homework for update to authenticated using(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid())) with check(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid()));

create policy "notices select" on public.notices for select to authenticated using(institute_id=private.current_institute() and (audience='all' or (audience='teachers' and private.current_role()='teacher') or (audience='students' and private.current_role()='student') or private.current_role()='admin'));
create policy "notices staff insert" on public.notices for insert to authenticated with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));
create policy "notices staff update" on public.notices for update to authenticated using(institute_id=private.current_institute() and (private.current_role()='admin' or author_id=auth.uid())) with check(institute_id=private.current_institute() and (private.current_role()='admin' or author_id=auth.uid()));

create policy "materials tenant select" on public.study_materials for select to authenticated using(institute_id=private.current_institute());
create policy "materials staff insert" on public.study_materials for insert to authenticated with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));
create policy "materials staff update" on public.study_materials for update to authenticated using(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid())) with check(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid()));

create policy "courses tenant select" on public.courses for select to authenticated using(institute_id=private.current_institute());
create policy "courses staff insert" on public.courses for insert to authenticated with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));
create policy "courses staff update" on public.courses for update to authenticated using(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid())) with check(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid()));
create policy "course sections select" on public.course_sections for select to authenticated using(course_id in(select id from public.courses where institute_id=private.current_institute()));
create policy "course sections staff insert" on public.course_sections for insert to authenticated with check(course_id in(select id from public.courses where institute_id=private.current_institute()) and (private.current_role()='admin' or exists(select 1 from public.courses c where c.id=course_id and c.teacher_id=auth.uid())));
create policy "course lessons select" on public.course_lessons for select to authenticated using(course_id in(select id from public.courses where institute_id=private.current_institute()));
create policy "course lessons staff insert" on public.course_lessons for insert to authenticated with check(course_id in(select id from public.courses where institute_id=private.current_institute()) and (private.current_role()='admin' or exists(select 1 from public.courses c where c.id=course_id and c.teacher_id=auth.uid())));

create policy "exams tenant select" on public.exams for select to authenticated using(institute_id=private.current_institute());
create policy "exams staff insert" on public.exams for insert to authenticated with check(institute_id=private.current_institute() and private.current_role() in ('admin','teacher'));
create policy "exams staff update" on public.exams for update to authenticated using(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid())) with check(institute_id=private.current_institute() and (private.current_role()='admin' or teacher_id=auth.uid()));
create policy "questions tenant select" on public.exam_questions for select to authenticated using(exam_id in(select id from public.exams where institute_id=private.current_institute()));
create policy "questions staff insert" on public.exam_questions for insert to authenticated with check(exam_id in(select id from public.exams where institute_id=private.current_institute()) and (private.current_role()='admin' or exists(select 1 from public.exams e where e.id=exam_id and e.teacher_id=auth.uid())));

create policy "attempts select" on public.exam_attempts for select to authenticated using(student_id=auth.uid() or (exam_id in(select id from public.exams where institute_id=private.current_institute()) and private.current_role() in ('admin','teacher')));
create policy "attempts student insert" on public.exam_attempts for insert to authenticated with check(student_id=auth.uid());
create policy "attempts student update" on public.exam_attempts for update to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());
create policy "answers select" on public.exam_answers for select to authenticated using(attempt_id in(select id from public.exam_attempts where student_id=auth.uid()) or attempt_id in(select ea.id from public.exam_attempts ea join public.exams e on e.id=ea.exam_id where e.institute_id=private.current_institute() and private.current_role() in ('admin','teacher')));
create policy "answers student insert" on public.exam_answers for insert to authenticated with check(attempt_id in(select id from public.exam_attempts where student_id=auth.uid()));

create policy "leads admin select" on public.leads for select to authenticated using(institute_id=private.current_institute() and private.current_role()='admin');
create policy "leads admin insert" on public.leads for insert to authenticated with check(institute_id=private.current_institute() and private.current_role()='admin');
create policy "leads admin update" on public.leads for update to authenticated using(institute_id=private.current_institute() and private.current_role()='admin') with check(institute_id=private.current_institute() and private.current_role()='admin');

create policy "timetable tenant select" on public.timetables for select to authenticated using(institute_id=private.current_institute());
create policy "timetable admin insert" on public.timetables for insert to authenticated with check(institute_id=private.current_institute() and private.current_role()='admin');
create policy "timetable admin update" on public.timetables for update to authenticated using(institute_id=private.current_institute() and private.current_role()='admin') with check(institute_id=private.current_institute() and private.current_role()='admin');

-- 11) Grants / Data API.
grant usage on schema public to authenticated,anon;
grant select,insert,update,delete on all tables in schema public to authenticated;
revoke all on all tables in schema public from anon;
alter default privileges in schema public grant select,insert,update,delete on tables to authenticated;
alter default privileges in schema public revoke all on tables from anon;

-- 12) Storage bucket for institute logos/materials.
insert into storage.buckets(id,name,public)
values('vidyadesk','vidyadesk',true)
on conflict(id) do update set public=true;
drop policy if exists "vidyadesk public read" on storage.objects;
drop policy if exists "vidyadesk auth upload" on storage.objects;
drop policy if exists "vidyadesk auth update" on storage.objects;
drop policy if exists "vidyadesk auth delete" on storage.objects;
create policy "vidyadesk public read" on storage.objects for select to public using(bucket_id='vidyadesk');
create policy "vidyadesk auth upload" on storage.objects for insert to authenticated with check(bucket_id='vidyadesk');
create policy "vidyadesk auth update" on storage.objects for update to authenticated using(bucket_id='vidyadesk') with check(bucket_id='vidyadesk');
create policy "vidyadesk auth delete" on storage.objects for delete to authenticated using(bucket_id='vidyadesk');

-- 13) Updated-at trigger.
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['institutes','profiles','teachers','batches','students','homework','courses'] LOOP
    execute format('drop trigger if exists trg_%s_updated on public.%I',t,t);
    execute format('create trigger trg_%s_updated before update on public.%I for each row execute function public.set_updated_at()',t,t);
  END LOOP;
END $$;

-- Remove the old tables only after successful migration of the data used above.
drop table if exists public.vd_legacy_class_join_requests cascade;
drop table if exists public.vd_legacy_class_memberships cascade;
drop table if exists public.vd_legacy_homework cascade;
drop table if exists public.vd_legacy_materials cascade;
drop table if exists public.vd_legacy_notices cascade;
drop table if exists public.vd_legacy_classes cascade;
drop table if exists public.vd_legacy_profiles cascade;

commit;

-- Fresh-project bootstrap note:
-- The first Auth user created after this migration is pending Student by default.
-- To make a brand-new first user an Admin, either use the SQL once below or extend the UI with a first-account setup screen:
-- insert into public.institutes(name) values('Your Institute') returning id;
-- update public.profiles set institute_id='<UUID>', role='admin', status='active' where id='<AUTH_USER_UUID>';
-- update public.institutes set owner_profile_id='<AUTH_USER_UUID>' where id='<UUID>';
