import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/utils/external_link.dart';
import '../domain/version_policy.dart';

/// A config/app olvasása. Hiba vagy hiányzó Firebase esetén nem blokkol.
final versionPromptProvider = FutureProvider<VersionPrompt>((ref) async {
  if (Firebase.apps.isEmpty) return VersionPrompt.none;
  try {
    final info = await PackageInfo.fromPlatform();
    final snap = await FirebaseFirestore.instance.doc('config/app').get();
    final data = snap.data();
    return versionPrompt(
      current: info.version,
      minVersion: data?['minVersion'] as String?,
      latestVersion: data?['latestVersion'] as String?,
    );
  } catch (_) {
    return VersionPrompt.none;
  }
});

/// Kötelező frissítésnél a teljes képernyő, különben a gyerek.
class VersionGate extends ConsumerStatefulWidget {
  const VersionGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends ConsumerState<VersionGate> {
  var _dismissedOptional = false;

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(versionPromptProvider).asData?.value;
    if (prompt == VersionPrompt.required) {
      return const _RequiredUpdate();
    }
    return Stack(
      children: [
        widget.child,
        if (prompt == VersionPrompt.optional && !_dismissedOptional)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _OptionalUpdate(
              onClose: () => setState(() => _dismissedOptional = true),
            ),
          ),
      ],
    );
  }
}

class _RequiredUpdate extends StatelessWidget {
  const _RequiredUpdate();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 56),
                const SizedBox(height: 24),
                Text(
                  'Új verzió érhető el. A folytatáshoz frissítsd az alkalmazást.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: openStoreListing,
                  child: const Text('Frissítés'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalUpdate extends StatelessWidget {
  const _OptionalUpdate({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const Expanded(child: Text('Új verzió érhető el.')),
            TextButton(
              onPressed: openStoreListing,
              child: const Text('Frissítés'),
            ),
            IconButton(
              tooltip: 'Bezárás',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
