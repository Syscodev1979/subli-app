import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_session.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/widgets/error_notice.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../data/safety_repository.dart';
import '../domain/content_report.dart';

Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetType targetType,
  required String targetId,
  required String targetAuthorId,
  required String targetPath,
  required String snapshot,
}) async {
  final session = ref.read(authGateProvider).asData?.value;
  if (session is! AuthSignedIn) return;
  final details = TextEditingController();
  var reason = ReportReason.offensive;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Jelentés', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                RadioGroup<ReportReason>(
                  groupValue: reason,
                  onChanged: (value) {
                    if (value != null) setState(() => reason = value);
                  },
                  child: Column(
                    children: [
                      for (final item in ReportReason.values)
                        RadioListTile<ReportReason>(
                          value: item,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.label),
                        ),
                    ],
                  ),
                ),
                TextField(
                  controller: details,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Részletek, ha szeretnéd',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: const Text('Jelentés elküldése'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  final text = details.text;
  details.dispose();
  if (sent != true || !context.mounted) return;
  try {
    await ref
        .read(safetyRepositoryProvider)
        .report(
          reporterId: session.user.id,
          targetType: targetType,
          targetId: targetId,
          targetAuthorId: targetAuthorId,
          targetPath: targetPath,
          reason: reason,
          details: text,
          snapshot: snapshot,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A jelentés elküldve. Az admin megnézi.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(errorSnackBar(authErrorMessage(error)));
  }
}
