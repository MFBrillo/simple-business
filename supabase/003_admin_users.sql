-- ============================================================
-- Adds an in-app admin role so approving a user's `status` no longer
-- requires the Supabase dashboard or a hand-written SQL statement — see
-- lib/screens/admin_screen.dart.
--
-- Run this in the Supabase SQL editor after 002_profiles_is_active.sql.
-- ============================================================

alter table public.users
  add column if not exists is_admin boolean not null default false;

-- ---------- is_admin_user(): security definer, mirrors is_active_user() ----------
-- Must be security definer: it's used inside policies ON public.users
-- itself, so a plain (non-definer) function would re-trigger those same
-- policies for its own internal select and recurse. security definer runs
-- as the function owner, which bypasses RLS for this lookup — same trick
-- Postgres/Supabase docs recommend for self-referential role checks.
create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select is_admin from public.users where id = auth.uid()),
    false
  );
$$;

-- ---------- widen the users table's RLS for admins ----------
-- Regular users still only ever see their own row; admins can see and
-- edit every row (to approve sign-ups / grant admin).
drop policy if exists "users_select_own" on public.users;
drop policy if exists "users_select_own_or_admin" on public.users;
create policy "users_select_own_or_admin" on public.users
  for select using (auth.uid() = id or public.is_admin_user());

drop policy if exists "users_update_admin" on public.users;
create policy "users_update_admin" on public.users
  for update using (public.is_admin_user()) with check (public.is_admin_user());

-- ---------- make yourself an admin ----------
-- Run once, by hand, replacing the email — this is the one step that still
-- can't happen from inside the app (nothing is an admin yet to grant it).
-- update public.users set is_admin = true where email = 'you@example.com';
