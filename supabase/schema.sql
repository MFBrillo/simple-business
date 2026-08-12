-- ============================================================
-- ProfitPilot schema for Supabase
-- Run this in the Supabase SQL editor (or as a migration file).
--
-- user_id defaults to auth.uid() so the app never has to send it on
-- insert — it's set server-side from the signed-in session and enforced
-- by the RLS policies below either way.
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- products ----------
create table public.products (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name          text not null,
  category      text not null,
  sku           text not null default '',
  price         numeric(12,2) not null default 0,
  material      numeric(12,2) not null default 0,
  packaging     numeric(12,2) not null default 0,
  labor         numeric(12,2) not null default 0,
  other         numeric(12,2) not null default 0,
  stock         integer not null default 0,
  unit          text not null default 'pc',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index products_user_id_idx on public.products(user_id);

-- ---------- sales ----------
create table public.sales (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  product_id    bigint not null references public.products(id) on delete restrict,
  qty           integer not null check (qty > 0),
  price         numeric(12,2) not null,
  method        text not null default 'Cash',
  sold_at       timestamptz not null default now(),
  created_at    timestamptz not null default now()
);

create index sales_user_id_idx on public.sales(user_id);
create index sales_product_id_idx on public.sales(product_id);
create index sales_sold_at_idx on public.sales(sold_at);

-- ---------- expenses ----------
create table public.expenses (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  description   text not null,
  category      text not null,
  amount        numeric(12,2) not null check (amount > 0),
  expense_date  date not null default current_date,
  notes         text not null default '',
  created_at    timestamptz not null default now()
);

create index expenses_user_id_idx on public.expenses(user_id);
create index expenses_expense_date_idx on public.expenses(expense_date);

-- ---------- settings (one row per user) ----------
create table public.settings (
  user_id               uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  business_name         text not null default '',
  currency_code         text not null default 'PHP',
  low_stock_threshold   integer not null default 10,
  default_margin        numeric(5,2) not null default 40,
  updated_at            timestamptz not null default now()
);

-- ---------- keep updated_at fresh ----------
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger products_set_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

create trigger settings_set_updated_at
  before update on public.settings
  for each row execute function public.set_updated_at();

-- ============================================================
-- Row Level Security — each user only sees their own rows
-- ============================================================
alter table public.products enable row level security;
alter table public.sales    enable row level security;
alter table public.expenses enable row level security;
alter table public.settings enable row level security;

create policy "products_owner" on public.products
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "sales_owner" on public.sales
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "expenses_owner" on public.expenses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "settings_owner" on public.settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
