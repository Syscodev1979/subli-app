import 'package:flutter/material.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';

/// A belépő képernyők közös, dísztelen kerete.
class AuthFrame extends StatelessWidget {
  const AuthFrame({
    required this.child,
    this.title,
    this.subtitle,
    this.onBack,
    this.logoSize = 120,
    this.screenKey,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Nyugalmi logóméret. Szűk képernyőn és billentyűzetnél kisebb.
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
      backgroundColor: dark ? AppColors.darkSurface : Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = media.viewInsets.bottom;
            final spare = constraints.maxHeight - 36 - bottomInset;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: spare < 0 ? 0 : spare),
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
                        Image.asset(
                          ClubConfig.logoAsset,
                          width: size,
                          height: size,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: 'Klublogó',
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
                        const SizedBox(height: 24),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
    return FilledButton(
      onPressed: busy ? () {} : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      child: busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
