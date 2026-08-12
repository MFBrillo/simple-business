import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenience accessor, e.g. `supabase.from('products').select()`.
SupabaseClient get supabase => Supabase.instance.client;
