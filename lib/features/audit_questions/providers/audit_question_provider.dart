import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/audit_question_model.dart';
import '../services/audit_question_service.dart';

final auditQuestionServiceProvider = Provider<AuditQuestionService>(
  (ref) => AuditQuestionService(ref.watch(apiServiceProvider)),
);

/// The active master questions, ordered for display. Consumed by the audit
/// sheet (row descriptions) and the action plan (row ordering). autoDispose so
/// it re-fetches whenever a consuming screen remounts — an admin's edits show
/// up the next time an auditor/owner opens the sheet.
final activeAuditQuestionsProvider =
    FutureProvider.autoDispose<List<AuditQuestionModel>>(
  (ref) => ref.watch(auditQuestionServiceProvider).listQuestions(),
);

/// Builds a name → description lookup from a question list, so a screen can
/// resolve the "what to check for" text dynamically (falling back to the
/// bundled constant when the fetch hasn't landed / a name isn't found).
Map<String, String> descriptionMapFrom(List<AuditQuestionModel> questions) {
  final map = <String, String>{};
  for (final q in questions) {
    final desc = q.description;
    if (desc != null && desc.isNotEmpty) map[q.name] = desc;
  }
  return map;
}

final auditQuestionAdminProvider =
    ChangeNotifierProvider<AuditQuestionAdminProvider>(
  (ref) => AuditQuestionAdminProvider(
    ref.watch(auditQuestionServiceProvider),
  ),
);

/// Admin-screen state: the full master list including deactivated questions,
/// with create / edit / deactivate / reactivate / reorder mutations.
class AuditQuestionAdminProvider extends ChangeNotifier {
  AuditQuestionAdminProvider(this._service);

  final AuditQuestionService _service;

  List<AuditQuestionModel> questions = [];
  bool isLoading = false;
  String? error;

  int _fetchSeq = 0;

  List<AuditQuestionModel> get activeQuestions =>
      questions.where((q) => q.isActive).toList();

  Future<void> fetch() async {
    final seq = ++_fetchSeq;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.listQuestions(includeInactive: true);
      if (seq != _fetchSeq) return;
      questions = result;
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

  Future<void> createQuestion({
    required String name,
    String? description,
  }) async {
    final created =
        await _service.createQuestion(name: name, description: description);
    questions = [...questions, created];
    _sort();
    notifyListeners();
  }

  Future<void> updateQuestion(
    String id, {
    String? name,
    String? description,
  }) async {
    final updated = await _service.updateQuestion(
      id,
      name: name,
      description: description,
    );
    _replace(updated);
  }

  Future<void> deactivateQuestion(String id) async {
    final updated = await _service.updateQuestion(id, isActive: false);
    _replace(updated);
  }

  Future<void> reactivateQuestion(String id) async {
    final updated = await _service.updateQuestion(id, isActive: true);
    _replace(updated);
  }

  /// Persists a reorder of the currently-active questions. [orderedActive] is
  /// the active list in its new top-to-bottom order; inactive questions keep
  /// their place and are appended so the server receives every id.
  Future<void> reorderActive(List<AuditQuestionModel> orderedActive) async {
    final inactive = questions.where((q) => !q.isActive).map((q) => q.id);
    final orderedIds = [
      ...orderedActive.map((q) => q.id),
      ...inactive,
    ];
    final result = await _service.reorder(orderedIds);
    questions = result;
    notifyListeners();
  }

  void _replace(AuditQuestionModel updated) {
    questions =
        questions.map((q) => q.id == updated.id ? updated : q).toList();
    _sort();
    notifyListeners();
  }

  void _sort() {
    questions.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.paramIndex.compareTo(b.paramIndex);
    });
  }
}
