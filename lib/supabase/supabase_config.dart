/// Supabase project URL + publishable key (formerly called the anon key),
/// supplied at **compile time** via `--dart-define` — never hardcoded here,
/// so they don't sit in plain source in git history.
///
/// This key is safe to ship in a client app — access is enforced by the
/// Row Level Security policies on each table (see `supabase/schema.sql`),
/// not by keeping this key secret. Still, keeping it out of source avoids
/// looking like a leaked secret to anyone scanning the repo, and means
/// rotating it doesn't require a code change.
///
/// Local dev: `flutter run --dart-define-from-file=dart_defines/supabase.local.json`
/// (copy `dart_defines/supabase.example.json` to that path and fill it in —
/// `supabase.local.json` is gitignored).
///
/// CI/GitHub Pages: the `deploy-pages.yml` workflow passes these from
/// repository secrets `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY`.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
