// Smoke test for AuthScreen — the app's actual entry point once Supabase
// credentials are filled in. Tested directly (bypassing ProfitPilotApp's
// SupabaseConfig.isConfigured gate, since the shipped config still has
// placeholders) at desktop/tablet/mobile widths to catch overflow bugs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:simple_business/screens/auth_screen.dart';
import 'package:simple_business/state/app_state.dart';
import 'package:simple_business/theme/app_theme.dart';

Future<void> _pumpAuthScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AuthScreen(),
      ),
    ),
  );
  await tester.pump();

  expect(tester.takeException(), isNull, reason: 'AuthScreen threw during render at $size');
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://test.supabase.co', publishableKey: 'test-anon-key');
  });

  testWidgets('AuthScreen renders at desktop width (1280x900)', (tester) async {
    await _pumpAuthScreen(tester, const Size(1280, 900));
    expect(find.text('ProfitPilot'), findsOneWidget);
    expect(find.text('Sign in to your business'), findsOneWidget);
  });

  testWidgets('AuthScreen renders at tablet width (760x900)', (tester) async {
    await _pumpAuthScreen(tester, const Size(760, 900));
  });

  testWidgets('AuthScreen renders at mobile width (375x800)', (tester) async {
    await _pumpAuthScreen(tester, const Size(375, 800));
  });

  testWidgets('Toggling to sign-up switches the form copy', (tester) async {
    await _pumpAuthScreen(tester, const Size(1280, 900));

    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pump();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });

  testWidgets('Submitting with empty fields shows a validation message', (tester) async {
    await _pumpAuthScreen(tester, const Size(1280, 900));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter both your email and password.'), findsOneWidget);
  });
}
