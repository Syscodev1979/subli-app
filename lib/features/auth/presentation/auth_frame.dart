import 'package:flutter/material.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';

/// A belépő képernyők közös háttere, logója és elsődleges gombja.
class AuthFrame extends StatelessWidget {
  const AuthFrame({
    required this.child,
    this.title,
    this.subtitle,
    this.onBack,
    this.logoSize = 132,
    this.screenKey,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Nagy logó nyugalmi mérete. Szűk képernyőn és billentyűzetnél kisebb.
  final double logoSize;
  final Key? screenKey;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final compact = media.viewInsets.bottom > 0 || media.size.height < 700;
    final size = compact ? (logoSize * 0.62).clamp(64.0, 88.0) : logoSize;
    return Scaffold(
      key: screenKey,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [
                    Color(0xFF4A121E),
                    Color(0xFF2A1820),
                    AppColors.darkSurface,
                  ]
                : const [
                    Color(0xFFF6E4E8),
                    Color(0xFFFFF8F6),
                    Color(0xFFFAFAFA),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -30,
              child: _Blob(
                diameter: 190,
                color: AppColors.gold.withValues(alpha: dark ? 0.16 : 0.28),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: _Blob(
                diameter: 210,
                color: (dark ? AppColors.burgundyDarkMode : AppColors.burgundy)
                    .withValues(alpha: dark ? 0.18 : 0.08),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = media.viewInsets.bottom;
                  final spare =
                      constraints.maxHeight - 36 - bottomInset;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: spare < 0 ? 0 : spare,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                        if (onBack != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: 'Vissza a bejelentkezéshez',
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back),
                            ),
                          ),
                        _LogoEntrance(
                          size: size,
                          glow: AppColors.gold.withValues(
                            alpha: dark ? 0.35 : 0.55,
                          ),
                        ),
                        if (title != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.62),
                                ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Material(
                          color: dark
                              ? const Color(0xFF2A2428)
                              : const Color(0xFFFFFFFF),
                          elevation: dark ? 0 : 2,
                          shadowColor: AppColors.burgundy.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                            child: child,
                          ),
                        ),
                      ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMid,
            AppColors.gradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _LogoEntrance extends StatefulWidget {
  const _LogoEntrance({required this.size, required this.glow});

  final double size;
  final Color glow;

  @override
  State<_LogoEntrance> createState() => _LogoEntranceState();
}

class _LogoEntranceState extends State<_LogoEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.glow,
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Image.asset(
              ClubConfig.logoAsset,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Klublogó',
            ),
          ),
        ),
      ),
    );
  }
}
