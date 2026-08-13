-- ============================================================
-- Tracks packaging/consumable supplies (Plastic Cup, Spoon, …) as running
-- stock counts — see lib/screens/expenses_screen.dart.
--
-- Restocked via Expenses: an expense with a quantity set adds that many
-- units to the supply named after its description (e.g. description
-- "Plastic Cup", quantity 100 → +100 to the "Plastic Cup" supply).
-- Every recorded sale then deducts 1 unit of *each* supply on hand,
-- regardless of which product was sold — see AppState.recordSale.
--
-- Run this in the Supabase SQL editor after 004_product_materials.sql.
-- ============================================================

alter table public.expenses
  add column if not exists quantity integer;

create table if not exists public.supplies (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name          text not null,
  quantity      integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists supplies_user_id_idx on public.supplies(user_id);

-- Reuses set_updated_at() from schema.sql.
drop trigger if exists supplies_set_updated_at on public.supplies;
create trigger supplies_set_updated_at
  before update on public.supplies
  for each row execute function public.set_updated_at();

alter table public.supplies enable row level security;

-- Same shape as products/sales/expenses: owner-only, gated on
-- is_active_user() from 002_profiles_is_active.sql.
drop policy if exists "supplies_owner" on public.supplies;
create policy "supplies_owner" on public.supplies
  for all using (auth.uid() = user_id and public.is_active_user())
  with check (auth.uid() = user_id and public.is_active_user());
