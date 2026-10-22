import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../app/theme_controller.dart';
import '../../app/theme_preference.dart';

/// Nap és hold között csúszó témakapcsoló.
class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  static const double width = 64;
  static const double height = 32;
  static const double knob = 26;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = ThemePreference.semantics(dark: dark);
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () => _toggle(context, ref, dark: dark),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: dark ? 1 : 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, t, _) {
              return SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _Track(amount: t)),
                    _FaintIcon(
                      alignment: Alignment.centerLeft,
                      icon: Icons.wb_sunny_rounded,
                      opacity: t.clamp(0, 1) * 0.45,
                      color: AppColors.goldLight,
                    ),
                    _FaintIcon(
                      alignment: Alignment.centerRight,
                      icon: Icons.nightlight_round,
                      opacity: (1 - t).clamp(0, 1) * 0.4,
                      color: AppColors.burgundyDark,
                    ),
                    Positioned(
                      left: 4 + (width - knob - 8) * t,
                      top: (height - knob) / 2,
                      child: _Knob(dark: dark, amount: t),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool dark,
  }) async {
    HapticFeedback.lightImpact();
    final next = dark ? ThemePreference.light : ThemePreference.dark;
    await ref.read(themePreferenceProvider.notifier).select(next);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          ThemePreference.snackBar(dark: next == ThemePreference.dark),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final darken = amount.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(ThemeSwitch.height / 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.goldLight),
          Opacity(
            opacity: darken,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.themeTrackNight, AppColors.burgundyDark],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: darken,
            child: const CustomPaint(painter: _StarPainter()),
          ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  static const _stars = <Offset>[
    Offset(12, 8),
    Offset(20, 18),
    Offset(30, 7),
    Offset(46, 11),
    Offset(52, 21),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xB3F3E6E9);
    for (final star in _stars) {
      canvas.drawCircle(star, star == const Offset(30, 7) ? 1.4 : 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => false;
}

class _FaintIcon extends StatelessWidget {
  const _FaintIcon({
    required this.alignment,
    required this.icon,
    required this.opacity,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Opacity(
          opacity: opacity,
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.dark, required this.amount});

  final bool dark;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      Colors.white,
      AppColors.themeKnobDark,
      amount.clamp(0, 1),
    )!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        width: ThemeSwitch.knob,
        height: ThemeSwitch.knob,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.35, end: 0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Icon(
            dark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            key: ValueKey<bool>(dark),
            size: 16,
            color: dark ? AppColors.burgundyLight : AppColors.gold,
          ),
        ),
      ),
    );
  }
}
