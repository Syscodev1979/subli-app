/// A jelentés indoka. A [value] kerül a Firestore-ba.
enum ReportReason {
  offensive('offensive', 'Sértő'),
  spam('spam', 'Kéretlen/reklám'),
  offtopic('offtopic', 'Nem odaillő'),
  other('other', 'Egyéb');

  const ReportReason(this.value, this.label);
  final String value;
  final String label;
}

enum ReportTargetType { post, comment, message, profile }

/// Egy bejelentés. Csak az admin olvassa.
class ContentReport {
  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetAuthorId,
    required this.targetPath,
    required this.reason,
    required this.details,
    required this.snapshot,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String targetAuthorId;
  final String targetPath;
  final String reason;
  final String details;
  final String snapshot;
  final String status;
  final DateTime createdAt;

  bool get isOpen => status == 'open';

  String get reasonLabel {
    for (final reason in ReportReason.values) {
      if (reason.value == this.reason) return reason.label;
    }
    return reason;
  }
}
