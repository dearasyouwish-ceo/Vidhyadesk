-- VidyaDesk: run this once in the SQL Editor of a NEW / EMPTY Supabase project.
-- This script is deliberately separate from index.html. It enables strict per-user data access.
-- Phone OTP must also be enabled in Supabase Authentication before using the app.
-- Do NOT run it on the previous legacy schema that used bigint class IDs without first
-- migrating it: that older table has different column names/types. This script does not delete data.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) >= 2),
  role text not null check (role in ('tutor','student')),
  phone text,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  name text not null check (char_length(trim(name)) >= 2),
  subject text,
  class_code text not null unique default upper(substr(replace(gen_random_uuid()::text,'-',''),1,6)),
  created_at timestamptz not null default now()
);

create table if not exists public.class_join_requests (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  student_name text not null,
  student_phone text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique(class_id, student_id)
);

create table if not exists public.class_memberships (
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  student_name text not null,
  student_phone text,
  approved_at timestamptz not null default now(),
  primary key(class_id, student_id)
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade,
  title text not null, body text not null, link text, created_at timestamptz not null default now()
);
create table if not exists public.homework (
  id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade,
  title text not null, body text not null, created_at timestamptz not null default now()
);
create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade,
  title text not null, body text not null, created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_join_requests enable row level security;
alter table public.class_memberships enable row level security;
alter table public.materials enable row level security;
alter table public.homework enable row level security;
alter table public.notices enable row level security;

-- Remove only the policies created by an earlier run of this script.
drop policy if exists "profile self" on public.profiles;
drop policy if exists "class owner or member reads class" on public.classes;
drop policy if exists "tutor creates own class" on public.classes;
drop policy if exists "tutor updates own class" on public.classes;
drop policy if exists "tutor deletes own class" on public.classes;
drop policy if exists "request participant read" on public.class_join_requests;
drop policy if exists "membership participant read" on public.class_memberships;

create policy "profile self" on public.profiles for all to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "class owner or member reads class" on public.classes for select to authenticated using (
  owner_id = auth.uid() or exists (select 1 from public.class_memberships m where m.class_id = classes.id and m.student_id = auth.uid())
);
create policy "tutor creates own class" on public.classes for insert to authenticated with check (
  owner_id = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'tutor')
);
create policy "tutor updates own class" on public.classes for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "tutor deletes own class" on public.classes for delete to authenticated using (owner_id = auth.uid());
create policy "request participant read" on public.class_join_requests for select to authenticated using (
  student_id = auth.uid() or exists (select 1 from public.classes c where c.id = class_join_requests.class_id and c.owner_id = auth.uid())
);
create policy "membership participant read" on public.class_memberships for select to authenticated using (
  student_id = auth.uid() or exists (select 1 from public.classes c where c.id = class_memberships.class_id and c.owner_id = auth.uid())
);

-- Security-definer functions hide class-code lookup from students and prevent self-approval.
create or replace function public.request_join_by_code(p_class_code text)
returns void language plpgsql security definer set search_path = public as $$
declare c public.classes; p public.profiles;
begin
  if auth.uid() is null then raise exception 'Please log in first'; end if;
  select * into p from public.profiles where id = auth.uid() and role = 'student';
  if not found then raise exception 'Only student accounts can request to join a class'; end if;
  select * into c from public.classes where class_code = upper(trim(p_class_code));
  if not found then raise exception 'No class found with that code'; end if;
  insert into public.class_join_requests(class_id,student_id,student_name,student_phone,status)
  values(c.id,auth.uid(),p.full_name,p.phone,'pending')
  on conflict(class_id,student_id) do update set student_name=excluded.student_name,student_phone=excluded.student_phone,status='pending',created_at=now(),reviewed_at=null;
end $$;

create or replace function public.review_join_request(p_request_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare req public.class_join_requests;
begin
  if auth.uid() is null or p_status not in ('approved','rejected') then raise exception 'Invalid request'; end if;
  select jr.* into req from public.class_join_requests jr join public.classes c on c.id=jr.class_id where jr.id=p_request_id and c.owner_id=auth.uid();
  if not found then raise exception 'Request not found or not your class'; end if;
  update public.class_join_requests set status=p_status,reviewed_at=now() where id=req.id;
  if p_status='approved' then
    insert into public.class_memberships(class_id,student_id,student_name,student_phone) values(req.class_id,req.student_id,req.student_name,req.student_phone)
    on conflict(class_id,student_id) do nothing;
  else
    delete from public.class_memberships where class_id=req.class_id and student_id=req.student_id;
  end if;
end $$;
revoke all on function public.request_join_by_code(text) from public;
revoke all on function public.review_join_request(uuid,text) from public;
grant execute on function public.request_join_by_code(text) to authenticated;
grant execute on function public.review_join_request(uuid,text) to authenticated;

-- Content: class owner may publish; only owner or approved students may read.
create or replace function public.add_content_policies(p_table regclass) returns void language plpgsql as $$
begin
 execute format('create policy "content read %s" on %s for select to authenticated using (exists (select 1 from public.classes c where c.id = class_id and (c.owner_id=auth.uid() or exists (select 1 from public.class_memberships m where m.class_id=c.id and m.student_id=auth.uid()))))',p_table,p_table);
 execute format('create policy "content owner write %s" on %s for all to authenticated using (exists (select 1 from public.classes c where c.id = class_id and c.owner_id=auth.uid())) with check (exists (select 1 from public.classes c where c.id = class_id and c.owner_id=auth.uid()))',p_table,p_table);
end $$;
select public.add_content_policies('public.materials');
select public.add_content_policies('public.homework');
select public.add_content_policies('public.notices');
drop function public.add_content_policies(regclass);
