-- VidyaDesk RLS preflight
-- Run this ONCE before supabase_schema_fixed.sql.
-- It creates the helper functions required by the schema's policy creation block.

begin;

create or replace function public.vd_my_institute_id()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_institute_id uuid;
begin
  select p.institute_id
    into v_institute_id
  from public.profiles p
  where p.id = auth.uid()
    and p.status = 'active';

  return v_institute_id;
end;
$$;

create or replace function public.vd_is_owner()
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'owner'
      and p.status = 'active'
  );
end;
$$;

grant execute on function public.vd_my_institute_id() to authenticated;
grant execute on function public.vd_is_owner() to authenticated;

commit;
