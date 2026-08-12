import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_screen.dart';
import 'state/app_state.dart';
import 'supabase/supabase_config.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/app_toast.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ProfitPilotApp(),
    ),
  );
}

class ProfitPilotApp extends StatelessWidget {
  const ProfitPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppState, ThemeMode>((s) => s.themeMode);

    return MaterialApp(
      title: 'ProfitPilot',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: SupabaseConfig.isConfigured ? const _AppRoot() : const _MissingConfigScreen(),
    );
  }
}

/// Shown instead of the app when `lib/supabase/supabase_config.dart` still
/// has its placeholder URL/anon key — avoids a confusing wall of network
/// errors on first run.
class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 32, color: colors.muted),
                const SizedBox(height: 16),
                Text('Supabase isn\'t configured yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.ink)),
                const SizedBox(height: 8),
                Text(
                  'Fill in your project URL and anon key in lib/supabase/supabase_config.dart, then restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the sign-in screen when there's no Supabase session, otherwise
/// waits for [AppState] to finish loading the account's data, then shows
/// the shell with toast/confirm overlays wrapping the active screen.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>(); // rebuild on auth changes too, not just isLoaded
    final state = context.read<AppState>();

    if (!state.isAuthenticated) {
      return const AuthScreen();
    }
    if (!state.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ConfirmDialogHost(
      child: AppToastOverlay(
        child: Shell(
          child: const _ActiveScreen(),
        ),
      ),
    );
  }
}

/// Single-page screen switch — mirrors the design's SPA navigation model.
/// [PageStorageKey] on each screen keeps scroll offsets from bleeding
/// between them (Shell's SingleChildScrollView resets to top on switch).
class _ActiveScreen extends StatelessWidget {
  const _ActiveScreen();

  @override
  Widget build(BuildContext context) {
    final screen = context.select<AppState, AppScreen>((s) => s.screen);
    // ProductFormScreen owns its own controller state, seeded from
    // editingId only in initState — key it by editingId too so switching
    // which product is being edited (while staying on the same AppScreen)
    // forces a fresh State instead of reusing stale controllers.
    final editingId = context.select<AppState, int?>((s) => s.editingId);
    return switch (screen) {
      AppScreen.dashboard => const DashboardScreen(key: ValueKey('dashboard')),
      AppScreen.products => const ProductsScreen(key: ValueKey('products')),
      AppScreen.addProduct => ProductFormScreen(key: ValueKey('addProduct-$editingId')),
      AppScreen.detail => const ProductDetailScreen(key: ValueKey('detail')),
      AppScreen.sales => const SalesScreen(key: ValueKey('sales')),
      AppScreen.expenses => const ExpensesScreen(key: ValueKey('expenses')),
      AppScreen.inventory => const InventoryScreen(key: ValueKey('inventory')),
      AppScreen.calculator => const CalculatorScreen(key: ValueKey('calculator')),
      AppScreen.reports => const ReportsScreen(key: ValueKey('reports')),
      AppScreen.settings => const SettingsScreen(key: ValueKey('settings')),
    };
  }
}
