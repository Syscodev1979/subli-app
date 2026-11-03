import 'package:flutter/material.dart';

import '../../app/constants.dart';

/// Hibaüzenet ikonnal. A szín önmagában nem hordozza a jelentést.
class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key, this.centered = false});

  final String message;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A #B45309 a sötét #121212 felületen csak 3,7:1, ezért ott világosabb borostyán.
    final color = theme.brightness == Brightness.dark
        ? AppColors.errorOnDark
        : theme.colorScheme.error;
    final style = theme.textTheme.bodyMedium?.copyWith(color: color);
    return Row(
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message,
            style: style,
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ),
      ],
    );
  }
}

/// Hibasáv ikonnal.
SnackBar errorSnackBar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.error_outline),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
