import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/utils/hungarian_date.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../../core/widgets/error_notice.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../data/safety_repository.dart';
import '../domain/content_report.dart';

final reportsProvider = StreamProvider<List<ContentReport>>((ref) {
  return ref.watch(safetyRepositoryProvider).watchReports();
});

/// Az admin jelentéslistája.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);
    return Scaffold(
      appBar: ClubAppBar(
        leading: IconButton(
          tooltip: 'Vissza',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.admin),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: ErrorNotice(authErrorMessage(error), centered: true)),
        data: (items) {
          final open = [
            for (final item in items)
              if (item.isOpen) item,
          ];
          if (open.isEmpty) {
            return const Center(child: Text('Nincs nyitott jelentés.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: open.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ReportCard(report: open[index]),
          );
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});

  final ContentReport report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  var _busy = false;

  Future<void> _act(String action) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .resolveReport(reportId: widget.report.id, action: action);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(errorSnackBar(authErrorMessage(error)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final profile = report.targetType == 'profile';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.reasonLabel} · ${report.targetType}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(formatHungarianDate(report.createdAt)),
            if (report.snapshot.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(report.snapshot),
            ],
            if (report.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(report.details),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!profile)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _act('hide'),
                    child: const Text('Elrejtés'),
                  ),
                if (!profile)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _act('delete'),
                    child: const Text('Törlés'),
                  ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _act('suspend'),
                  child: const Text('Felfüggesztés'),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _act('close'),
                  child: const Text('Lezárás'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
