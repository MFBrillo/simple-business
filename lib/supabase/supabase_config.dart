/// Fill these in from your Supabase project (Project Settings → API →
/// "Publishable key", formerly called the anon key).
///
/// This key is safe to ship in a client app — access is enforced by the
/// Row Level Security policies on each table (see the schema in
/// `supabase/schema.sql`), not by keeping this key secret. Still, if this
/// repo is public, consider moving these to `--dart-define` build args so
/// you're not pointing strangers at your project by default.
class SupabaseConfig {
  static const url = 'https://mllmkfgqyxkxzwcyuphh.supabase.co';
  static const publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sbG1rZmdxeXhreHp3Y3l1cGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0NzQzMDIsImV4cCI6MjA3MzA1MDMwMn0.151HtAvJeS9Xuv6al1aaR2-F-k8IZwrWv5baFmWBMtk';

  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT_REF') &&
      !publishableKey.contains('YOUR_PUBLISHABLE_KEY');
}
