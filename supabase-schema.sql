-- MyNBA 2K27 Creator database setup
-- Run this once in Supabase > SQL Editor > New query.

create extension if not exists pgcrypto;

create table if not exists public.careers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Career 1',
  state jsonb not null default '{}'::jsonb,
  version integer not null default 1,
  sort_order integer not null default 0,
  is_shared boolean not null default false,
  share_slug text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shared_career_needs_slug check (not is_shared or share_slug is not null)
);

create index if not exists careers_user_id_idx on public.careers(user_id);
create index if not exists careers_user_sort_idx on public.careers(user_id, sort_order);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  theme text not null default 'auto' check (theme in ('auto', 'light', 'dark')),
  last_tab text not null default 'Games',
  current_career uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep profiles.current_career optional and clear it if that career is deleted.
do $$ begin
  alter table public.profiles
    add constraint profiles_current_career_fkey
    foreign key (current_career) references public.careers(id) on delete set null;
exception when duplicate_object then null;
end $$;

-- Automatically update updated_at and increment the version when a career changes.
create or replace function public.touch_career_row()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' then
    new.version := old.version + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists careers_touch_row on public.careers;
create trigger careers_touch_row
before update on public.careers
for each row execute function public.touch_career_row();

create or replace function public.touch_profile_row()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_row on public.profiles;
create trigger profiles_touch_row
before update on public.profiles
for each row execute function public.touch_profile_row();

-- Enforce a maximum of eight careers per account.
create or replace function public.enforce_career_limit()
returns trigger
language plpgsql
as $$
begin
  if (select count(*) from public.careers where user_id = new.user_id
      and (tg_op = 'INSERT' or id <> new.id)) >= 8 then
    raise exception 'You can have up to 8 careers.' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

drop trigger if exists careers_limit_before_write on public.careers;
create trigger careers_limit_before_write
before insert or update of user_id on public.careers
for each row execute function public.enforce_career_limit();

alter table public.careers enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "Users can view their own careers" on public.careers;
create policy "Users can view their own careers"
on public.careers for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can create their own careers" on public.careers;
create policy "Users can create their own careers"
on public.careers for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their own careers" on public.careers;
create policy "Users can update their own careers"
on public.careers for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own careers" on public.careers;
create policy "Users can delete their own careers"
on public.careers for delete to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can view their own profile" on public.profiles;
create policy "Users can view their own profile"
on public.profiles for select to authenticated
using (auth.uid() = id);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
on public.profiles for insert to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

grant select, insert, update, delete on public.careers to authenticated;
grant select, insert, update on public.profiles to authenticated;

-- A deliberately limited public view for shared career recaps.
-- It does not expose the full career state or account ID.
create or replace view public.shared_recaps
with (security_barrier = true)
as
select share_slug, name, state -> 'ld' as seasons, updated_at
from public.careers
where is_shared = true and share_slug is not null;

grant select on public.shared_recaps to anon, authenticated;
