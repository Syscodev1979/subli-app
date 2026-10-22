import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/constants.dart';

/// Kerek, bordó gomb, ami a lista tetejére görget.
class ScrollToTopButton extends StatelessWidget {
  const ScrollToTopButton({
    required this.visible,
    required this.onPressed,
    super.key,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.6),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !visible,
          child: ExcludeSemantics(
            excluding: !visible,
            child: Semantics(
              button: true,
              label: 'Ugrás a tetejére',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                elevation: visible ? 4 : 0,
                shadowColor: const Color(0x66000000),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onPressed();
                  },
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientMid,
                          AppColors.gradientEnd,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
