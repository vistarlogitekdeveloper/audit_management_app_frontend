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

  /// 'all' | 'pending' | 'submitted' | 'overdue' | 'closed'.
  /// All non-'all' values are valid backend ActionPlan.status values and are
  /// sent verbatim as the ?status= query param.
  String filter = 'all';
  List<ActionPlanSummary> plans = [];
  bool isLoading = false;
  String? error;

  /// Monotonic request id — see [UserProvider.fetchUsers]. Guards against a
  /// slow earlier fetch overwriting the result of a newer filter selection.
  int _fetchSeq = 0;

  Future<void> fetch() async {
    final seq = ++_fetchSeq;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Backend ?status= accepts pending/submitted/overdue/closed; 'all' must
      // omit the param. Every non-'all' tab key is a valid value, so pass it
      // through unchanged.
      final passToBackend = filter == 'all' ? null : filter;
      final result = await _service.list(status: passToBackend);
      if (seq != _fetchSeq) return;
      plans = result;
    } catch (e) {
      if (seq != _fetchSeq) return;
      error = e.toString();
    } finally {
      if (seq == _fetchSeq) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void setFilter(String value) {
    filter = value;
    fetch();
  }

  /// The backend already filters by [filter] (via ?status=), so the loaded
  /// list is what should be shown — no extra client-side filtering needed.
  List<ActionPlanSummary> get visible => plans;
}
