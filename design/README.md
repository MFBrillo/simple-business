# Handoff: ProfitPilot — Product Profit Calculator & Small Business Management App

## Overview
A small-business management app for Philippine micro-entrepreneurs (food stalls, home bakers, milk-tea shops). The owner adds products with a per-unit cost breakdown, records sales, logs expenses, tracks stock, and instantly sees profit and margin. Currency is Philippine Peso (₱). Ten screens, one shell, live client-side math.

## About the Design Files
`Profit Pilot.dc.html` (plus its runtime `support.js`) is a **design reference created in HTML** — a working prototype showing intended look and behavior, not production code to copy. The task is to **recreate these designs in your target codebase** (React/Next, Vue, Flutter, SwiftUI, native Android…) using its existing patterns, component library, and state layer. If no environment exists yet, pick the framework that fits — for this app, React + TypeScript + Tailwind (web) or React Native/Flutter (mobile-first) are natural choices, with a local DB (SQLite/IndexedDB) since owners work offline.

Open the HTML file directly in a browser to inspect behavior; all state is in-memory.

## Fidelity
**High-fidelity.** Final colors, typography, spacing, radii, states, copy, and interactions. Recreate the UI closely with your existing libraries. All data is realistic sample data — replace with real persistence.

## Screens / Views

### Shell (all screens)
- **Desktop (>900px):** fixed left sidebar, 246px wide, `background: --card`, `border-right: 1px solid --line`, padding 20px 14px, sticky full height. Contents: logo lockup (34px rounded-11px green square with "₱", 15px/800 wordmark "ProfitPilot", 11px muted business name), 8 nav buttons, and a bottom "This month" net-profit card (radius 14px, padding 14px; green tint when positive, red tint when negative — never show a loss in a success color).
- **Nav items:** 10px 12px padding, radius 11px, gap 11px, 17px stroke icon (stroke-width 1.7) + 14px label. Hover `--hover`; active `background: --green-soft; color: --green-ink; font-weight: 700`.
- **Topbar:** sticky, `--card` background, bottom 1px `--line`, padding 16px 28px. Left: 19px/800 page title with -0.02em tracking + 12px muted subtitle (both change per screen). Right: green "＋ Record Sale" button (10px 15px, radius 11px), 38px theme toggle (☾/☀), 38px avatar tile with business initials.
- **Content area:** padding 24px 28px 60px, vertical flex, gap 20px.
- **Mobile (≤900px):** sidebar hidden (`display:none !important` — inline styles otherwise win), fixed bottom tab bar (`--card`, top 1px `--line`, padding 9px 8px + `env(safe-area-inset-bottom)`): Home, Products, a 52×46px green ＋ FAB (radius 16px) that jumps to Sales, Calc, Reports. Tab labels 10.5px/600 under 19px icons.
- **≤600px:** KPI grids force 2 columns, card padding 16px, topbar padding 11px 13px, inputs 16px font (prevents iOS zoom), the topbar "Record Sale" button hides (the FAB covers it).

### 1. Dashboard
Purpose: today at a glance.
- **KPI row:** `grid-template-columns: repeat(auto-fit, minmax(184px,1fr)); gap:14px`. 5 cards: Today's sales, Today's profit (green ink), Today's expenses (red), Items sold, Inventory value. Card = `--card` bg, 1px `--line`, radius 16px, padding 16px 17px, `--shadow`. Label 12px/600 muted, value 24px/800 tabular-nums -0.02em, note 11.5px muted.
- **Chart card** (radius 18px, padding 20px): "Sales, cost & profit / Last 7 days" + inline legend (9px rounded swatches). Grouped bar chart, 7 day columns, bars 26% width, radius 5px 5px 0 0, max height 150px: sales `--bar`, cost `--amber`, profit `--green`. Day label 11px/600 muted.
- **Top performing products table:** Product (name 700 + 11px muted category) | Units | Revenue | Profit (800, green ink). Header row 11.5px uppercase 0.05em muted; rows separated by 1px `--line`; row hover `--hover`.
- **Recent transactions list:** rows of 34px rounded-11px badge (↑ green tint for sales / ↓ red tint for expenses), title 13.5px/700 + 11.5px muted meta, right-aligned amount (`+₱…` green / `−₱…` red) with 11px sub-line.

### 2. Products
- Toolbar: search input (max-width 280px), "N products" count, right-aligned green "＋ Add Product".
- Card grid `repeat(auto-fill, minmax(280px,1fr)); gap:15px`. Each card (radius 18px, padding 18px): 42px initials tile (`--green-soft`/`--green-ink`), name 15px/800, "Category · SKU" 11.5px muted, status pill top-right (11px/700, radius 99px). 2×2 stat grid: Selling price, Unit cost (amber), Profit/unit (green ink), Stock. Margin bar: 7px track `--hover`, green fill at margin %. Actions row: View / Edit (outlined) / Delete (outlined, red text).
- **Empty state** when search matches nothing: dashed-border card, 48px glyph tile, "No products match “query”", helper line, green Add Product button.

### 3. Add / Edit Product
Two-column `repeat(auto-fit, minmax(320px,1fr))`.
- **Left form card:** Product name, Category (select), SKU, Selling price ₱ | divider | "Cost breakdown — per unit": Material, Packaging, Labor, Other, Initial stock, Unit (select). Fields in `repeat(auto-fit, minmax(150px,1fr))` grid, gap 13px. Labels 12px/700 `--ink-2`, stacked above input, gap 6px. Buttons: green Save product / Save changes + outlined Cancel.
- **Right summary card (sticky, top 96px):** solid green panel (radius 16px, padding 20px, white text) — "Profit per unit" 36px/800, margin pill + verdict text ("Healthy margin" ≥40%, "Thin — consider raising price" ≥20%, "Very thin margin", "Losing money per unit" if negative). Below: rows for Selling price, Total unit cost (amber), Profit per unit, Profit margin, Break-even price; then the formula footnote in 12px muted.

### 4. Product Details
Back link → Products. Left card: striped SVG image placeholder (150px tall, radius 14px, monospace caption "product shot → drop image here"), name 20px/800, "Category · SKU · N units on hand", 4 fact tiles (`--bg`, radius 13px): Selling price, Unit cost, Profit/unit, Margin. Actions: green Edit product + outlined Add stock.
Right column: "Sales performance" (4 tiles: Total units sold, Total revenue, Total cost, Total profit) and "Sales & profit over time" 7-column 2-bar chart (130px max height, sales `--bar` + profit `--green`).

### 5. Sales
- **Record a sale card:** Product select (label shows "Name · ₱price · stock unit"; picking one auto-fills price), Quantity + Selling price side by side, payment-method pill row (Cash / GCash / Bank Transfer / Other; selected = `--green-soft` bg, `--green` border, `--green-ink` text), amber inline warning when quantity exceeds stock or product is out of stock, then full-width green "Record sale · ₱total".
- **Sale summary card:** 2×2 tiles (Quantity, Unit price, Sales, Profit — profit tile on `--green-soft`), then formula rows: "Revenue = price × qty", "Cost = unit cost × qty", Margin, Stock after sale.
- **Sales history table** (min-width 720px, horizontal scroll on mobile): Date | Product | Qty | Sales | Cost (amber) | Profit (green, 800) | Payment (grey pill) | Void button (red outline).

### 6. Expenses
- 3 KPI cards: Today's expenses (red), This month's expenses (red), Largest category (amber value = category name, note = amount).
- **Add expense card:** Description, then Category (select of the 8 categories) / Amount ₱ / Date (native date input) / Notes in a 2-col grid; full-width **red** "Add expense" button.
- **Spending by category card:** per-category label + amount and an 8px progress bar scaled to the largest category (colors cycle amber / red / `--bar`).
- **Expense log table:** Date | Description (+ muted notes line) | Category (red-tint pill) | Amount (red, 800) | Delete.
- Categories: Transportation, Packaging, Utilities, Marketing, Delivery, Rent, Supplies, Miscellaneous.

### 7. Inventory
- 4 KPI cards: Total products, Total stock, Low/out of stock (amber), Inventory value (green ink).
- Table (min-width 700px): Product (+ category) | Stock (800) | Unit | Cost/unit | Inventory value | Status pill | Add stock + History buttons. Header line shows the current low-stock threshold.
- Status logic: `stock <= 0` → "Out of stock" (red tint); `stock <= lowStockThreshold` → "Low stock" (amber tint); else "In stock" (green tint).
- **Add stock modal:** overlay `rgba(10,16,14,.45)`, sheet radius 20px padding 24px max-width 390px, title + "Product — currently N unit", quantity field, Cancel / green Add stock.

### 8. Profit Calculator (hero screen)
- **Left input card:** Product name; grid of Selling price, Material, Packaging, Labor, Other, Quantity. Buttons: green "Save as product", outlined "Reset".
- **Right hero panel:** `linear-gradient(180deg, --green, --green-ink)`, radius 20px, padding 24px, white text. "Profit per unit" at 46px/800 (-0.035em), two translucent pills (Margin, Cost), divider, then a 3-column strip: Revenue ×qty, Total cost, Expected profit (19px/800 each).
- **Target profit calculator card:** "Desired margin" label with the live % at 26px/800 green ink, native range slider 5–80 (`accent-color: --green`), 5/40/80 tick labels, then a `--green-soft` result block: "Recommended selling price" 32px/800 + explainer, and an outlined "Use this price above" button that writes the price back into the calculator inputs.
  - `recommendedPrice = unitCost / (1 − desiredMargin/100)`.

### 9. Reports
- Filter bar card (radius 18px, padding 16px 18px): Date range, Product, Category selects + right-aligned Export PDF / Export Excel / Print (outlined). Changing a filter fires a toast.
- 5 KPI cards: Total sales, Total cost (amber), Total profit (green), Average margin, Units sold.
- 3 chart cards: "Sales & profit trend" (2-bar 7-day chart), "Profit by product" (horizontal bars, green), "Expense breakdown" (horizontal bars, category colors).

### 10. Settings
- **Business profile card:** business name, 54px logo tile + Upload logo button, Currency select (₱ PHP / $ USD), Low stock threshold, "Default profit margin" with inline % value and slider (10–70).
- **Appearance card:** Light / Dark buttons; selected gets a `--green` border.
- **Lists card:** Categories, Units, Payment methods as grey chips (radius 99px).
- **Data card:** Back up data, Restore, "Reset sample data" (red text, confirm dialog).

## Interactions & Behavior
- **Navigation:** single-page screen switch, scroll resets to top. Products/Add Product/Product Details all keep the Products nav item active.
- **Live math:** every price/cost/quantity keystroke recomputes cost, profit, margin, revenue and totals immediately (no submit step).
- **Record sale:** appends to sales history with a real timestamp ("Today, 2:40 PM"), decrements product stock (floored at 0), resets quantity to 1, fires a toast with the profit earned. Blocks with a toast if quantity ≤ 0.
- **Save product:** validates non-empty name and price > 0 (toast otherwise); add prepends to the list, edit patches in place; returns to Products with a toast.
- **Destructive actions** (delete product, void sale, reset data) open a **confirm dialog**: red-tint 42px "!" tile, title, body, Cancel + red CTA. Overlay fades in (`fadeIn .15s`), sheet pops (`popIn .2s`).
- **Toasts:** bottom-center pill, `--ink` background / `--bg` text, radius 14px, green ✓ dot, `toastIn .22s ease`, auto-dismiss after 2.6s, single timer (new toast replaces old).
- **Stock warning:** amber inline banner in the sale form when the sale would oversell or the product is out of stock.
- **Theme:** light/dark toggle in topbar and Settings; sets `data-theme` on `<html>`, all colors come from CSS custom properties.
- **Hover/active:** buttons `filter: brightness(1.06)` on hover, `translateY(1px)` on active; table/list rows tint to `--hover`; inputs get `border-color: --green` + 3px `--green-soft` focus ring.
- **Responsive:** breakpoints at 900px (sidebar → bottom tabs) and 600px (2-up KPIs, tighter padding, 16px inputs). Wide tables scroll horizontally inside `overflow-x:auto` wrappers.

## State Management
```
screen: 'dashboard'|'products'|'addProduct'|'detail'|'sales'|'expenses'|'inventory'|'calculator'|'reports'|'settings'
theme: 'light'|'dark'
search: string
editingId: number|null            // doubles as "selected product" for the detail screen
products: [{id,name,cat,sku,price,mat,pack,labor,other,stock,unit}]
sales:    [{id,pid,qty,price,method,date,day}]   // day 0 = today
expenses: [{id,desc,cat,amount,date,notes}]
form:     product/calculator inputs (strings, parsed on use)
sale:     {productId,qty,price,method}
exp:      {desc,cat,amount,date,notes}
filter:   {range,product,category}
settings: {businessName,currency,lowStock,defaultMargin}
target:   {margin}
toast / confirm / stockModal: transient UI state
```
Derived per render (never stored): per-sale revenue/cost/profit, today's totals, month totals, inventory value, per-product aggregates, chart heights, status pills. In production, persist products/sales/expenses/settings locally and sync; keep derived values computed.

## Important Calculation Logic
```
unitCost      = material + packaging + labor + other
profitPerUnit = sellingPrice − unitCost
margin %      = profitPerUnit / sellingPrice × 100
revenue       = sellingPrice × quantity
totalCost     = unitCost × quantity
profit        = revenue − totalCost
recommended   = unitCost / (1 − targetMargin/100)
monthNet      = Σ sales profit − Σ expenses      // red styling when negative
```
Money format: `₱` + `toLocaleString('en-PH')`, 2 decimals for unit values, 0 decimals for summary figures. Use tabular figures (`font-variant-numeric: tabular-nums`) on every number.

## Design Tokens
Light (`:root`) / Dark (`[data-theme="dark"]`):
| Token | Light | Dark |
|---|---|---|
| `--bg` | `#f4f6f5` | `#0d1211` |
| `--card` | `#ffffff` | `#151b19` |
| `--ink` | `#101613` | `#e9efec` |
| `--ink-2` | `#2c3733` | `#cbd6d1` |
| `--muted` | `#6d7a74` | `#8f9d97` |
| `--line` | `#e6eae8` | `#232c29` |
| `--green` | `oklch(0.60 0.14 152)` | `oklch(0.72 0.15 152)` |
| `--green-soft` | `oklch(0.95 0.04 152)` | `oklch(0.30 0.06 152)` |
| `--green-ink` | `oklch(0.45 0.12 152)` | `oklch(0.80 0.14 152)` |
| `--red` | `oklch(0.58 0.17 27)` | `oklch(0.68 0.17 27)` |
| `--red-soft` | `oklch(0.95 0.04 27)` | `oklch(0.30 0.07 27)` |
| `--amber` | `oklch(0.72 0.14 68)` | `oklch(0.78 0.14 68)` |
| `--amber-soft` | `oklch(0.95 0.05 68)` | `oklch(0.30 0.06 68)` |
| `--hover` | `oklch(0.96 0.006 152)` | `oklch(0.24 0.01 152)` |
| `--bar` | `oklch(0.45 0.02 200)` | `oklch(0.70 0.02 200)` |
| `--shadow` | `0 1px 2px rgba(16,24,20,.05), 0 8px 24px -18px rgba(16,24,20,.25)` | `0 1px 2px rgba(0,0,0,.4)` |

- **Type:** Plus Jakarta Sans (400/500/600/700/800); IBM Plex Mono only for the image-placeholder caption. Scale: 11 / 11.5 / 12 / 12.5 / 13 / 13.5 / 15 (section titles, 800) / 17 / 19 (page title) / 21 / 24 (KPI) / 32 / 36 / 46 (calculator hero). Negative tracking (-0.02 to -0.035em) on numbers ≥19px.
- **Spacing:** 4 / 6 / 8 / 10 / 13 / 14 / 16 / 18 / 20 / 22 / 24 / 28.
- **Radius:** 9 (small buttons) / 11 (buttons, fields) / 13–14 (tiles) / 16 (KPI cards) / 18 (panels) / 20 (modals, hero) / 99 (pills).
- **Motion:** `toastIn .22s`, `fadeIn .15s`, `popIn .2s`, button transitions `filter .15s / transform .1s`.

## Assets
No image assets. Icons are inline SVGs (stroke 1.7, 20-unit viewBox: dashboard squares, bag, trend arrow, coin circle, box, calculator, bar chart, gear). Product imagery is an intentional striped SVG placeholder — swap for real product photos. Fonts load from Google Fonts.

## Sample Data
`Aling Nena's Kitchen` with 6 products (Gulaman Jelly ₱15 / ₱8 cost, Special Burger ₱50 / ₱34, Wintermelon Milk Tea ₱50 / ₱30 (low stock), Buko Pandan ₱45 / ₱25 (out of stock), Siomai 4pcs ₱30 / ₱17, Puto Cheese ₱12 / ₱6.50), 14 sales across 8 days, 7 expenses. Replace entirely — it exists only to show every state (in stock / low / out, positive / negative month).

## Files
- `Profit Pilot.dc.html` — the full prototype (markup + logic; all styling inline plus a small token/media-query block in the head).
- `support.js` — runtime needed only to open the prototype locally. Not part of the design.

To view: open `Profit Pilot.dc.html` in a browser, keeping it next to `support.js`.
