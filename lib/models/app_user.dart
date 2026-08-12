/// A row in the `users` table — one per signed-up account, admin-visible
/// only (see `supabase/002_profiles_is_active.sql` and
/// `supabase/003_admin_users.sql` for the RLS behind this).
class AppUser {
  final String id;
  final String email;
  final String name;
  final String storeName;
  final String status; // 'Active' | 'Inactive'
  final bool isAdmin;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.storeName,
    required this.status,
    required this.isAdmin,
    required this.createdAt,
  });

  bool get isActive => status == 'Active';

  AppUser copyWith({String? status, bool? isAdmin}) => AppUser(
        id: id,
        email: email,
        name: name,
        storeName: storeName,
        status: status ?? this.status,
        isAdmin: isAdmin ?? this.isAdmin,
        createdAt: createdAt,
      );

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        storeName: json['storename'] as String? ?? '',
        status: json['status'] as String? ?? 'Inactive',
        isAdmin: json['is_admin'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
