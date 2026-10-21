import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Üzenetek az edzőkkel. A csevegés később készül el.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Üzenetek',
      message: 'Az üzenetek a következő lépésben készülnek el.',
    );
  }
}
