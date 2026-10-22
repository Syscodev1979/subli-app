import 'package:flutter/material.dart';

import '../../../app/constants.dart';

/// Lebegő chat gomb a hírfolyam sarkában, olvasatlan jelvénnyel.
class ChatButton extends StatelessWidget {
  const ChatButton({required this.unread, required this.onPressed, super.key});

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = unread == 0
        ? 'Üzenetek'
        : 'Üzenetek, $unread olvasatlan beszélgetés';
    return Semantics(
      button: true,
      label: label,
      child: Hero(
        tag: 'club-chat',
        child: Material(
          color: Colors.transparent,
          elevation: 4,
          shadowColor: const Color(0x66000000),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Ink(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
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
                    child: Icon(Icons.chat_bubble, color: Colors.white),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: _Badge(count: unread),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
