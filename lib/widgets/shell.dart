import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/app_screen.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';

class _NavItem {
  final AppScreen screen;
  final String label;
  final IconData icon;
  const _NavItem(this.screen, this.label, this.icon);
}

const _navItems = [
  _NavItem(AppScreen.dashboard, 'Dashboard', Icons.grid_view_rounded),
  _NavItem(AppScreen.products, 'Products', Icons.shopping_bag_outlined),
  _NavItem(AppScreen.sales, 'Sales', Icons.trending_up_rounded),
  _NavItem(AppScreen.expenses, 'Expenses', Icons.payments_outlined),
  _NavItem(AppScreen.inventory, 'Inventory', Icons.inventory_2_outlined),
  _NavItem(AppScreen.calculator, 'Calculator', Icons.calculate_outlined),
  _NavItem(AppScreen.reports, 'Reports', Icons.bar_chart_rounded),
  _NavItem(AppScreen.settings, 'Settings', Icons.settings_outlined),
];

/// Shown only to admins (see `AppState.isAdmin`), appended after Settings.
const _adminNavItem = _NavItem(AppScreen.admin, 'Admin', Icons.admin_panel_settings_outlined);

/// Products / Add Product / Product Details all keep the Products nav item active.
AppScreen _navScreenFor(AppScreen screen) {
  if (screen == AppScreen.addProduct || screen == AppScreen.detail) return AppScreen.products;
  return screen;
}

const _titles = <AppScreen, (String, String)>{
  AppScreen.dashboard: ('Dashboard', "Today's overview at a glance"),
  AppScreen.products: ('Products', 'Manage what you sell'),
  AppScreen.addProduct: ('Add Product', 'Set price and cost breakdown'),
  AppScreen.detail: ('Product Details', 'Performance for this product'),
  AppScreen.sales: ('Sales', 'Record and review sales'),
  AppScreen.expenses: ('Expenses', 'Track what you spend'),
  AppScreen.inventory: ('Inventory', 'Stock levels at a glance'),
  AppScreen.calculator: ('Profit Calculator', 'Price it right, every time'),
  AppScreen.reports: ('Reports', 'Trends across your business'),
  AppScreen.settings: ('Settings', 'Business profile & preferences'),
  AppScreen.admin: ('Admin', 'Approve and manage user accounts'),
};

/// App shell: fixed sidebar + topbar on desktop (>900px), bottom tab bar
/// on mobile. Wraps whichever screen widget is currently active.
class Shell extends StatelessWidget {
  final Widget child;
  const Shell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > AppBreakpoints.sidebarToTabs;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      drawer: isDesktop ? null : const Drawer(child: SafeArea(child: _Sidebar(isDrawer: true))),
      body: Row(
        children: [
          if (isDesktop) const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                const _Topbar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      width <= AppBreakpoints.compact ? 16 : AppSpacing.s28,
                      AppSpacing.s24,
                      width <= AppBreakpoints.compact ? 16 : AppSpacing.s28,
                      isDesktop ? 60 : 24,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  /// True when rendered inside the mobile [Drawer] rather than the
  /// permanent desktop sidebar column — drops the fixed 246px width and
  /// right border so it fills whatever width the Drawer gives it.
  final bool isDrawer;
  const _Sidebar({this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.watch<AppState>();
    final active = _navScreenFor(state.screen);
    final net = state.monthNet;

    return Container(
      width: isDrawer ? double.infinity : 246,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: colors.card,
        border: isDrawer ? null : Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.green, borderRadius: BorderRadius.circular(11)),
                child: const Text('₱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ProfitPilot', style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(
                      state.settings.businessName,
                      style: TextStyle(color: colors.muted, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (final item in [..._navItems, if (state.isAdmin) _adminNavItem])
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _NavButton(item: item, isActive: item.screen == active),
            ),
          const Spacer(),
          _MonthCard(net: net, symbol: state.settings.currencySymbol),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _NavButton({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: isActive ? colors.greenSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        hoverColor: colors.hover,
        onTap: () {
          context.read<AppState>().goTo(item.screen);
          // No-op when there's no open drawer (e.g. on desktop).
          Scaffold.maybeOf(context)?.closeDrawer();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(item.icon, size: 17, color: isActive ? colors.greenInk : colors.ink2),
              const SizedBox(width: 11),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? colors.greenInk : colors.ink2,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final double net;
  final String symbol;
  const _MonthCard({required this.net, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final positive = net >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: positive ? colors.greenSoft : colors.redSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.muted)),
          const SizedBox(height: 4),
          Text(
            formatMoney(net, symbol),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: positive ? colors.greenInk : colors.red,
            ),
          ),
          Text('Net profit', style: TextStyle(fontSize: 11, color: colors.muted)),
        ],
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.watch<AppState>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > AppBreakpoints.sidebarToTabs;
    final compact = width <= AppBreakpoints.compact;
    final (title, subtitle) = _titles[state.screen]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 28, vertical: compact ? 11 : 16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(Icons.menu_rounded, color: colors.ink2),
                tooltip: 'Menu',
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colors.ink, letterSpacing: -0.02)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: colors.muted)),
              ],
            ),
          ),
          // Without a bottom-tab FAB to cover it, "Record Sale" stays
          // reachable at every width — just icon-only once space is tight.
          if (compact)
            Material(
              color: colors.green,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => context.read<AppState>().goTo(AppScreen.sales),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => context.read<AppState>().goTo(AppScreen.sales),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: const Text('＋ Record Sale', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          const SizedBox(width: 10),
          _ThemeToggle(),
          const SizedBox(width: 10),
          _AvatarTile(businessName: state.settings.businessName),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.watch<AppState>();
    final isDark = state.themeMode == ThemeMode.dark;
    return Material(
      color: colors.hover,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.read<AppState>().toggleTheme(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18, color: colors.ink2),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final String businessName;
  const _AvatarTile({required this.businessName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = businessName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.greenSoft, borderRadius: BorderRadius.circular(11)),
      child: Text(initials, style: TextStyle(color: colors.greenInk, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
