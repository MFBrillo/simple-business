// Smoke test: SupabaseConfig reads from --dart-define at compile time (see
// lib/supabase/supabase_config.dart), so a plain `flutter test` run with no
// defines passed sees it as unconfigured — the app should show the
// friendly setup screen rather than crashing into network errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:simple_business/main.dart';
import 'package:simple_business/state/app_state.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // AppState's constructor touches supabase.auth regardless of whether
    // SupabaseConfig.isConfigured is true, so Supabase still needs *some*
    // initialized client here — these values are unrelated to the app's
    // own (unset) --dart-define config.
    await Supabase.initialize(url: 'https://test.supabase.co', publishableKey: 'test-anon-key');
  });

  testWidgets('Shows the "Supabase not configured" screen with no --dart-define set', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ProfitPilotApp(),
      ),
    );
    await tester.pump();

    expect(find.text("Supabase isn't configured yet"), findsOneWidget);
  });
}
