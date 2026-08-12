-- ============================================================
-- Wires up the `users` table you created by hand in the Table Editor
-- (id uuid pk default gen_random_uuid(), email, name, storename,
-- email_confirmed, status text default 'Inactive', created_at, update_at).
--
-- New sign-ups start with status = 'Inactive' — this is an approval-gate
-- model, not just a lock: an admin must flip a row to 'Active' (via the
-- Table Editor or a SQL statement) before that user can use the app.
--
-- If you already ran an earlier version of this file that created a
-- `profiles` table, this drops it first — everything now lives on your
-- `users` table instead.
-- ============================================================

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop table if exists public.profiles;

-- ---------- 1. auto-create a row on signup (email only) ----------
-- Explicitly sets id = the auth user's own id (overriding the table's
-- gen_random_uuid() default) so RLS can match auth.uid() = id. Other
-- columns (name, storename, email_confirmed) are left for your edit form.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill for any auth users created before this trigger existed.
insert into public.users (id, email)
select id, email from auth.users
on conflict (id) do nothing;

-- ---------- 2. RLS ----------
alter table public.users enable row level security;

-- Users can read their own row (so the app can explain why it's signing
-- them out) but there's no insert/update/delete policy for regular users —
-- only an admin using the dashboard or the service-role key can write to
-- this table, including approving a user by setting status = 'Active'.
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);

-- ---------- 3. keep update_at fresh on admin edits ----------
create or replace function public.set_update_at()
returns trigger as $$
begin
  new.update_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists users_set_update_at on public.users;
create trigger users_set_update_at
  before update on public.users
  for each row execute function public.set_update_at();

-- ---------- 4. gate the rest of the app on status = 'Active' ----------
-- Fails CLOSED: a missing row or any status other than 'Active' (including
-- the 'Inactive' default) blocks access — matches the approval-gate intent.
create or replace function public.is_active_user()
returns boolean
language sql
stable
as $$
  select coalesce(
    (select status = 'Active' from public.users where id = auth.uid()),
    false
  );
$$;

drop policy "products_owner" on public.products;
create policy "products_owner" on public.products
  for all using (auth.uid() = user_id and public.is_active_user())
  with check (auth.uid() = user_id and public.is_active_user());

drop policy "sales_owner" on public.sales;
create policy "sales_owner" on public.sales
  for all using (auth.uid() = user_id and public.is_active_user())
  with check (auth.uid() = user_id and public.is_active_user());

drop policy "expenses_owner" on public.expenses;
create policy "expenses_owner" on public.expenses
  for all using (auth.uid() = user_id and public.is_active_user())
  with check (auth.uid() = user_id and public.is_active_user());

drop policy "settings_owner" on public.settings;
create policy "settings_owner" on public.settings
  for all using (auth.uid() = user_id and public.is_active_user())
  with check (auth.uid() = user_id and public.is_active_user());
