import '../../../core/utils/helpers.dart';

class ActionPlanSummary {
  const ActionPlanSummary({
    required this.id,
    required this.auditSheetId,
    required this.auditPlanId,
    required this.projectName,
    required this.projectLocation,
    required this.auditDate,
    required this.dueDate,
    required this.status,
    required this.itemsTotal,
    required this.itemsOpen,
    required this.itemsInProgress,
    required this.itemsClosed,
    required this.daysRemaining,
    this.auditorName = '',
    this.itemsReviewPending = 0,
    this.itemsReviewApproved = 0,
    this.itemsReviewRejected = 0,
    this.isReviewComplete = false,
  });

  final String id;
  final String auditSheetId;
  final String auditPlanId;
  final String projectName;
  final String projectLocation;
  final DateTime auditDate;
  final DateTime dueDate;
  final String status;
  final int itemsTotal;
  final int itemsOpen;
  final int itemsInProgress;
  final int itemsClosed;
  final int daysRemaining;
  final String auditorName;

  /// Per-item review state counters introduced for the auditor review flow.
  /// Default to 0 when the backend hasn't populated them yet.
  final int itemsReviewPending;
  final int itemsReviewApproved;
  final int itemsReviewRejected;

  /// Backend flag: true when every item is review_status = 'approved'.
  /// Used to enable the auditor's "Close Audit" button.
  final bool isReviewComplete;

  bool get isOverdue => status == 'overdue' || daysRemaining < 0;
  bool get isClosed => status == 'closed' || itemsTotal > 0 && itemsClosed == itemsTotal;

  factory ActionPlanSummary.fromJson(Map<String, dynamic> json) {
    final project = AppHelpers.asStringMap(json['project']);
    final auditor = AppHelpers.asStringMap(json['auditor']);
    // Review counters may arrive flat (snake_case or camelCase) OR nested
    // under a `review_counts` / `reviewCounts` object. Try each in turn so
    // a backend shape change doesn't silently zero out the chips.
    final reviewCounts = AppHelpers.asStringMap(json['review_counts']) ??
        AppHelpers.asStringMap(json['reviewCounts']);
    int pickInt(List<Object?> candidates) {
      for (final c in candidates) {
        if (c != null) return AppHelpers.parseInt(c);
      }
      return 0;
    }

    // Derive per-item review counts from the embedded `items` array as a
    // last-resort fallback for backends that haven't surfaced the
    // aggregated counters on the list endpoint yet.
    int derivedPending = 0, derivedApproved = 0, derivedRejected = 0;
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is! Map) continue;
        final status = (item['review_status'] ?? item['reviewStatus'])
                ?.toString()
                .toLowerCase() ??
            'pending';
        if (status == 'approved') {
          derivedApproved++;
        } else if (status == 'rejected') {
          derivedRejected++;
        } else {
          derivedPending++;
        }
      }
    }

    return ActionPlanSummary(
      id: json['id']?.toString() ?? '',
      auditSheetId: json['audit_sheet_id']?.toString() ?? '',
      auditPlanId: json['audit_plan_id']?.toString() ?? '',
      projectName: project?['name']?.toString() ?? '',
      projectLocation: project?['location']?.toString() ?? '',
      auditDate: DateTime.tryParse(json['audit_date']?.toString() ?? '') ??
          DateTime.now(),
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      itemsTotal: AppHelpers.parseInt(json['items_total']),
      itemsOpen: AppHelpers.parseInt(json['items_open']),
      itemsInProgress: AppHelpers.parseInt(json['items_in_progress']),
      itemsClosed: AppHelpers.parseInt(json['items_closed']),
      daysRemaining: AppHelpers.parseInt(json['daysRemaining']),
      auditorName: auditor?['name']?.toString() ?? '',
      itemsReviewPending: pickInt([
        json['items_review_pending'],
        json['itemsReviewPending'],
        json['review_pending'],
        reviewCounts?['pending'],
        rawItems is List ? derivedPending : null,
      ]),
      itemsReviewApproved: pickInt([
        json['items_review_approved'],
        json['itemsReviewApproved'],
        json['review_approved'],
        reviewCounts?['approved'],
        rawItems is List ? derivedApproved : null,
      ]),
      itemsReviewRejected: pickInt([
        json['items_review_rejected'],
        json['itemsReviewRejected'],
        json['review_rejected'],
        reviewCounts?['rejected'],
        rawItems is List ? derivedRejected : null,
      ]),
      isReviewComplete:
          json['is_review_complete'] == true || json['isReviewComplete'] == true,
    );
  }
}
