import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

/// Destructive-action confirm sheet: red-tint 42px "!" tile, title, body,
/// Cancel + red CTA. Overlay `fadeIn .15s`, sheet `popIn .2s`.
///
/// Wrap the app once with [ConfirmDialogHost]; screens trigger it via
/// `context.read<AppState>().confirm(...)`.
class ConfirmDialogHost extends StatelessWidget {
  final Widget child;
  const ConfirmDialogHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final request = state.confirmRequest;
    final colors = context.colors;

    return Stack(
      children: [
        child,
        if (request != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: 1,
            child: Container(
              color: const Color(0x730A100E),
              alignment: Alignment.center,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                builder: (context, scale, sheet) => Transform.scale(scale: scale, child: sheet),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppRadius.modal),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.redSoft,
                          borderRadius: BorderRadius.circular(AppRadius.tile),
                        ),
                        child: Text('!', style: TextStyle(color: colors.red, fontWeight: FontWeight.w800, fontSize: 20)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        request.title,
                        style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.body,
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 13.5,
                          height: 1.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.dismissConfirm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.ink,
                                side: BorderSide(color: colors.line),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: state.acceptConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                              ),
                              child: Text(request.confirmLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
