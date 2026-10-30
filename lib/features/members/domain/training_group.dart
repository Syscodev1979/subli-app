import 'package:flutter/material.dart';

import '../../../app/constants.dart';

/// Edzéscsoport a `groups` gyűjteményben.
class TrainingGroup {
  const TrainingGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String color;
  final String description;
  final DateTime createdAt;

  Color get colorValue {
    final hex = color.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null || hex.length != 6) return AppColors.burgundy;
    return Color(0xFF000000 | value);
  }
}

/// Az első, üres listán felajánlott csoportok. Létrehozásuk nem kötelező.
const suggestedGroups = [
  (name: 'Kezdők', color: '#2E7D32', description: ''),
  (name: 'Haladók', color: '#1F6FEB', description: ''),
  (name: 'Versenycsapat', color: '#6B1E2E', description: ''),
  (name: 'Felnőtt csoport', color: '#C9A227', description: ''),
];
