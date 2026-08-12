// Smoke test: with real Supabase credentials configured and no persisted
// session, the app should land on the sign-in screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:simple_business/main.dart';
import 'package:simple_business/state/app_state.dart';
import 'package:simple_business/supabase/supabase_config.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  });

  testWidgets('Shows the sign-in screen when there is no session', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ProfitPilotApp(),
      ),
    );
    await tester.pump();

    expect(find.text('ProfitPilot'), findsOneWidget);
    expect(find.text('Sign in to your business'), findsOneWidget);
  });
}
