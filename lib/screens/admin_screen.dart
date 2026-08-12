import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

/// Admin-only: approve new sign-ups and manage account status. The nav item
/// that leads here is already hidden for non-admins (see widgets/shell.dart);
/// the access-denied fallback below is defense in depth for anyone who lands
/// on this screen without `AppState.isAdmin` some other way — the actual
/// enforcement is server-side RLS (`supabase/003_admin_users.sql`).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.isAdmin) state.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;

    if (!state.isAdmin) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: "You don't have access to this page"),
            const SizedBox(height: 8),
            Text(
              'Admin access is required to approve or manage user accounts.',
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
          ],
        ),
      );
    }

    final pending = state.users.where((u) => !u.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                title: 'Users',
                subtitle: pending == 0
                    ? '${state.users.length} account${state.users.length == 1 ? '' : 's'}'
                    : '${state.users.length} account${state.users.length == 1 ? '' : 's'} · $pending awaiting approval',
                trailing: IconButton(
                  onPressed: () => state.loadUsers(),
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  tooltip: 'Refresh',
                  color: colors.ink2,
                ),
              ),
              const SizedBox(height: 14),
              if (state.users.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No accounts to show yet.', style: TextStyle(fontSize: 13, color: colors.muted)),
                  ),
                )
              else
                for (final u in state.users) ...[
                  _UserRow(user: u),
                  if (u != state.users.last) Divider(height: 1, color: colors.line),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    final displayName = user.name.isNotEmpty ? user.name : user.email;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.ink),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 8),
                      const StatusPill(label: 'Admin', tone: PillTone.neutral),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.storeName.isEmpty ? user.email : '${user.email} · ${user.storeName}',
                  style: TextStyle(fontSize: 11.5, color: colors.muted),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${DateFormat('MMM d, yyyy').format(user.createdAt)}',
                  style: TextStyle(fontSize: 11, color: colors.muted),
                ),
                const SizedBox(height: 6),
                StatusPill(label: user.status, tone: user.isActive ? PillTone.green : PillTone.amber),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              if (user.isActive) {
                state.confirm(
                  title: 'Deactivate $displayName?',
                  body: 'They’ll be signed out and blocked from the app until reactivated.',
                  confirmLabel: 'Deactivate',
                  onConfirm: () => state.setUserStatus(user.id, 'Inactive'),
                );
              } else {
                state.setUserStatus(user.id, 'Active');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? colors.red : colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
            ),
            child: Text(
              user.isActive ? 'Deactivate' : 'Activate',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
