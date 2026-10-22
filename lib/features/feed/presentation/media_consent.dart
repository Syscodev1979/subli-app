import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const _consentKey = 'media_consent_ack';
const _documentConsentKey = 'document_consent_ack';

/// Egyszeri figyelmeztetés gyermekfotó feltöltése előtt.
Future<bool> ensureMediaConsent(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_consentKey) == true) return true;
  if (!context.mounted) return false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: const Text(
          'Csak olyan gyermekről tegyél fel fotót vagy videót, akinek a szülője hozzájárult.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Megértettem'),
          ),
        ],
      );
    },
  );
  if (accepted == true) {
    await prefs.setBool(_consentKey, true);
    return true;
  }
  return false;
}

/// Egyszeri figyelmeztetés, mielőtt gyermek dokumentuma felkerülne.
Future<bool> ensureDocumentConsent(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_documentConsentKey) == true) return true;
  if (!context.mounted) return false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: const Text(
          'Csak olyan gyermek dokumentumát oszd meg, akinek a szülője hozzájárult.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Megértettem'),
          ),
        ],
      );
    },
  );
  if (accepted == true) {
    await prefs.setBool(_documentConsentKey, true);
    return true;
  }
  return false;
}
