-- (already applied) participant height for BMI + weigh-in every 3 weeks
alter table public.participants add column height_cm numeric(4,1) check (height_cm between 100 and 250);
alter table public.settings drop constraint settings_freq_weeks_check;
alter table public.settings add constraint settings_freq_weeks_check check (freq_weeks in (2, 3, 4));
