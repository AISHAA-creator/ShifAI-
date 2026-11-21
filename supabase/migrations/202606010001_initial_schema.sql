create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "Users can insert their own profile"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = id);
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', '')
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table if not exists public.lab_reports (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  report_date date not null,
  fasting_glucose_mg_dl double precision check (fasting_glucose_mg_dl > 0),
  fasting_insulin_uiu_ml double precision check (fasting_insulin_uiu_ml > 0),
  hba1c_percent double precision check (hba1c_percent > 0),
  other_markers jsonb not null default '[]'::jsonb
    check (jsonb_typeof(other_markers) = 'array'),
  notes text,
  homa_ir double precision generated always as (
    case
      when fasting_glucose_mg_dl is not null
       and fasting_insulin_uiu_ml is not null
      then fasting_glucose_mg_dl * fasting_insulin_uiu_ml / 405.0
      else null
    end
  ) stored,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists lab_reports_user_date_idx
  on public.lab_reports (user_id, report_date desc);

alter table public.lab_reports enable row level security;
create policy "Users can read their own lab reports"
  on public.lab_reports for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can insert their own lab reports"
  on public.lab_reports for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own lab reports"
  on public.lab_reports for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own lab reports"
  on public.lab_reports for delete to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.user_preferences (
  user_id uuid not null references auth.users (id) on delete cascade,
  preference_key text not null,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, preference_key)
);

alter table public.user_preferences enable row level security;
create policy "Users can read their own preferences"
  on public.user_preferences for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can write their own preferences"
  on public.user_preferences for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create table if not exists public.coaching_completions (
  user_id uuid not null references auth.users (id) on delete cascade,
  completion_date date not null,
  tip_id text not null,
  completed boolean not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, completion_date, tip_id)
);

alter table public.coaching_completions enable row level security;
create policy "Users can read their own coaching completions"
  on public.coaching_completions for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can write their own coaching completions"
  on public.coaching_completions for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete
  on public.profiles, public.lab_reports, public.user_preferences,
     public.coaching_completions
  to authenticated;
