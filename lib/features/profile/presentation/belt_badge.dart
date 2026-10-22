import 'package:flutter/material.dart';

import '../../../app/club_config.dart';

/// Színes öv-csík és a fokozat felirata, például „5. kyu – kék öv”.
class BeltBadge extends StatelessWidget {
  const BeltBadge({required this.belt, this.compact = false, super.key});

  final BeltGrade belt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final darkInk = belt.color.computeLuminance() > 0.7;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 28 : 36,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(
            color: belt.color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: darkInk ? const Color(0xFFB7B0B3) : Colors.transparent,
            ),
          ),
          child: belt.stripe == null
              ? null
              : Align(
                  alignment: Alignment.center,
                  child: Container(height: 2, color: belt.stripe),
                ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            belt.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
