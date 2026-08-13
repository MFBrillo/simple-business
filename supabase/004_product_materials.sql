-- ============================================================
-- Adds a per-product ingredient/recipe breakdown, so "Material" cost can
-- be computed from actual ingredient costs + batch yield instead of typed
-- in as one flat number — see lib/screens/product_form_screen.dart.
--
-- Run this in the Supabase SQL editor after 003_admin_users.sql.
-- ============================================================

alter table public.products
  add column if not exists materials jsonb not null default '[]'::jsonb,
  add column if not exists batch_yield integer not null default 1;

-- Each element of `materials` is `{"name": text, "unit_cost": number, "quantity": number}`.
-- `material` (the existing flat per-unit-cost column) stays the source of
-- truth the rest of the app reads from (unitCost, margins, reports…) —
-- when a product has ingredients, the app keeps `material` in sync as
-- (sum of unit_cost * quantity) / batch_yield; when it doesn't, `material`
-- is just typed in directly like before. Existing products are unaffected:
-- `materials` defaults to an empty list, so nothing changes until you add
-- ingredients to a product.
