/// The 10 screens of the app shell, matching the `screen` field in
/// `design/README.md`'s state shape. Navigation is a single-page switch
/// (no route stack) — the Shell just swaps which screen widget it shows.
enum AppScreen {
  dashboard,
  products,
  addProduct,
  detail,
  sales,
  expenses,
  inventory,
  calculator,
  reports,
  settings,
}
