-- ============================================================
-- Adds a soft-delete flag to products, so deleting a product that already
-- has sales history doesn't hit `sales_product_id_fkey` (products.sales
-- uses `on delete restrict` — see schema.sql) and fail outright.
--
-- lib/state/app_state.dart's deleteProduct now tries a real delete first;
-- if Postgres rejects it with a foreign_key_violation (because sales
-- reference the product), it falls back to setting archived = true
-- instead. Archived products are hidden from the Products catalog and the
-- "record a sale" picker, but stay fully intact for past sales/reports to
-- resolve their name and cost from — matching the existing "Past sales
-- stay in history" copy on the delete-confirm dialog, which previously
-- wasn't actually true once a product had any sales.
--
-- Run this in the Supabase SQL editor after 006_expenses_batch_ref.sql.
-- ============================================================

alter table public.products
  add column if not exists archived boolean not null default false;

create index if not exists products_archived_idx on public.products(archived);
