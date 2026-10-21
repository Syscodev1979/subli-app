import 'package:flutter/material.dart';

import '../../../core/utils/hungarian_date.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Edzésnaptár. A naptár komponens később készül el; a dátum már magyarul látszik.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Naptár',
      message: 'Mai nap: ${formatHungarianDate(DateTime.now())}',
    );
  }
}
