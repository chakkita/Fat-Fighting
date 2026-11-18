-- Judges (กรรมการ): can record check-ins only. Managed by admin via Edge Function (service role). (already applied)
create table public.judges (user_id uuid primary key references auth.users(id) on delete cascade, display_name text not null, email text not null, created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now());
alter table public.judges enable row level security;
create policy "read judges" on public.judges for select to authenticated using (user_id = (select auth.uid()) or exists (select 1 from public.admins a where a.user_id = (select auth.uid())));
grant select on public.judges to authenticated;
create policy "judge insert checkins" on public.checkins for insert to authenticated with check (exists (select 1 from public.judges j where j.user_id = (select auth.uid())));
create policy "judge update checkins" on public.checkins for update to authenticated using (exists (select 1 from public.judges j where j.user_id = (select auth.uid()))) with check (exists (select 1 from public.judges j where j.user_id = (select auth.uid())));
alter table public.checkins add column updated_by uuid references auth.users(id) on delete set null, add column updated_at timestamptz not null default now();
create function public.set_checkin_audit() returns trigger language plpgsql set search_path = '' as $$ begin new.updated_by := (select auth.uid()); new.updated_at := now(); return new; end $$;
create trigger checkins_audit before insert or update on public.checkins for each row execute function public.set_checkin_audit();
