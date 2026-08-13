class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

//upgrade-1318931438.cos.ap-beijing.myqcloud.com/display-100/100G/JL DGT software.zip
