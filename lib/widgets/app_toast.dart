import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

/// Bottom-center toast pill: `--ink` background / `--bg` text, green ✓ dot,
/// `toastIn .22s ease`. Auto-dismiss is driven by [AppState]'s single timer.
class AppToastOverlay extends StatelessWidget {
  final Widget child;
  const AppToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = context.watch<AppState>().toastMessage;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (widget, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: widget),
                );
              },
              child: message == null
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : Material(
                      key: ValueKey(message),
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.ink,
                          borderRadius: BorderRadius.circular(AppRadius.tileLg),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              message,
                              style: TextStyle(color: colors.bg, fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
