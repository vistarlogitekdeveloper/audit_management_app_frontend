import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/action_plan_summary.dart';
import '../services/action_plan_tracker_service.dart';

final actionPlanTrackerServiceProvider = Provider<ActionPlanTrackerService>(
  (ref) => ActionPlanTrackerService(ref.watch(apiServiceProvider)),
);

final actionPlanTrackerProvider =
    ChangeNotifierProvider<ActionPlanTrackerProvider>(
  (ref) => ActionPlanTrackerProvider(ref.watch(actionPlanTrackerServiceProvider)),
);

class ActionPlanTrackerProvider extends ChangeNotifier {
  ActionPlanTrackerProvider(this._service);

  final ActionPlanTrackerService _service;

  /// 'all' | 'pending' | 'submitted' | 'overdue' | 'closed'
  String filter = 'all';
  List<ActionPlanSummary> plans = [];
  bool isLoading = false;
  String? error;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Backend statuses are pending/submitted/overdue.
      // 'closed' and 'all' need client-side filtering.
      final passToBackend =
          (filter == 'pending' || filter == 'submitted' || filter == 'overdue')
              ? filter
              : null;
      plans = await _service.list(status: passToBackend);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String value) {
    filter = value;
    fetch();
  }

  List<ActionPlanSummary> get visible {
    if (filter == 'closed') return plans.where((p) => p.isClosed).toList();
    if (filter == 'open') {
      return plans.where((p) => !p.isClosed && !p.isOverdue).toList();
    }
    return plans;
  }
}
