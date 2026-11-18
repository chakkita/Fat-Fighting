-- Fat Fighting schema: public read, admin-only write (already applied to project FatFighting)
create table public.admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create table public.settings (id int primary key default 1 check (id = 1), start_date date not null, end_date date not null, freq_weeks int not null default 4 check (freq_weeks in (2,4)), updated_at timestamptz not null default now(), check (end_date > start_date));
create table public.participants (id text primary key, first_name text not null, last_name text not null, position text not null default '', start_weight numeric(5,1) not null check (start_weight > 0), start_waist numeric(5,1) not null check (start_waist > 0), photo text not null default '', created_at timestamptz not null default now());
create table public.checkins (participant_id text not null references public.participants(id) on delete cascade, checkpoint int not null check (checkpoint >= 1), weight numeric(5,1) not null check (weight > 0), waist numeric(5,1) check (waist > 0), created_at timestamptz not null default now(), primary key (participant_id, checkpoint));

alter table public.admins enable row level security;
alter table public.settings enable row level security;
alter table public.participants enable row level security;
alter table public.checkins enable row level security;

create policy "admins read own row" on public.admins for select to authenticated using (user_id = (select auth.uid()));
create policy "public read settings" on public.settings for select to anon, authenticated using (true);
create policy "public read participants" on public.participants for select to anon, authenticated using (true);
create policy "public read checkins" on public.checkins for select to anon, authenticated using (true);

do $$
declare t text;
begin
  foreach t in array array['settings','participants','checkins'] loop
    execute format('create policy "admin insert %1$s" on public.%1$s for insert to authenticated with check (exists (select 1 from public.admins a where a.user_id = (select auth.uid())))', t);
    execute format('create policy "admin update %1$s" on public.%1$s for update to authenticated using (exists (select 1 from public.admins a where a.user_id = (select auth.uid()))) with check (exists (select 1 from public.admins a where a.user_id = (select auth.uid())))', t);
    execute format('create policy "admin delete %1$s" on public.%1$s for delete to authenticated using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())))', t);
  end loop;
end $$;

grant select on public.settings, public.participants, public.checkins to anon, authenticated;
grant insert, update, delete on public.settings, public.participants, public.checkins to authenticated;
grant select on public.admins to authenticated;
alter publication supabase_realtime add table public.settings, public.participants, public.checkins;

insert into public.settings (id, start_date, end_date, freq_weeks)
values (1, date_trunc('year', now())::date + 4, date_trunc('year', now())::date + 116, 4);
