-- ============================================================
-- Adds a nullable batch_ref column to expenses, used to de-duplicate
-- "Save batch as expense" writes from the Products form (one product's
-- ingredient list saved as itemised expenses, one row per ingredient) —
-- see lib/screens/product_form_screen.dart.
--
-- batch_ref is "<product_id>:<yyyy-MM-dd>", the same value on every row
-- written by one batch-save click. Before inserting, the app checks for
-- existing rows with that batch_ref to warn about saving the same
-- product's batch twice in a day; this column carries no DB-level
-- uniqueness constraint (a resave is a deliberate user choice, not an
-- error), so it's just indexed for a fast lookup. Null for expenses added
-- the normal way (Expenses screen's "Add expense" form).
--
-- Run this in the Supabase SQL editor after 005_supplies.sql.
-- ============================================================

alter table public.expenses
  add column if not exists batch_ref text;

create index if not exists expenses_batch_ref_idx on public.expenses(batch_ref);
