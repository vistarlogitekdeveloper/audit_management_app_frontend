import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../audit_sheet/models/audit_sheet_model.dart';
import '../../audit_sheet/providers/audit_sheet_provider.dart';
import 'audit_report_screen.dart';

/// Auditor-facing wrapper around [AuditReportScreen]. Adds a banner that
/// shows acknowledgement state and lets the auditor jump back into the
/// sheet for edits while the owner has not yet acknowledged the audit.
class AuditorReportViewScreen extends ConsumerStatefulWidget {
  const AuditorReportViewScreen({super.key, required this.auditId});

  final String auditId;

  @override
  ConsumerState<AuditorReportViewScreen> createState() =>
      _AuditorReportViewScreenState();
}

class _AuditorReportViewScreenState
    extends ConsumerState<AuditorReportViewScreen> {
  AuditSheetModel? _sheet;
  bool _loadingSheet = true;
  Object? _sheetError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSheet);
  }

  Future<void> _loadSheet() async {
    setState(() {
      _loadingSheet = true;
      _sheetError = null;
    });
    try {
      _sheet = await ref
          .read(auditSheetServiceProvider)
          .getSheet(widget.auditId);
    } catch (e) {
      _sheetError = e;
    } finally {
      if (mounted) setState(() => _loadingSheet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AcknowledgementBanner(
          sheet: _sheet,
          loading: _loadingSheet,
          error: _sheetError,
          onEdit: () => context.go('/auditor/audit/${widget.auditId}'),
          onRetry: _loadSheet,
        ),
        const SizedBox(height: 14),
        AuditReportScreen(auditId: widget.auditId),
      ],
    );
  }
}

class _AcknowledgementBanner extends StatelessWidget {
  const _AcknowledgementBanner({
    required this.sheet,
    required this.loading,
    required this.error,
    required this.onEdit,
    required this.onRetry,
  });

  final AuditSheetModel? sheet;
  final bool loading;
  final Object? error;
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppPanel(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Checking acknowledgement status…'),
          ],
        ),
      );
    }

    if (error != null || sheet == null) {
      return AppPanel(
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Could not load acknowledgement status.'),
            ),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.ghost,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }

    final status = sheet!.status.toLowerCase();
    final isAcknowledged = status == 'acknowledged' ||
        status == 'completed' ||
        sheet!.acknowledgedAt != null;

    if (isAcknowledged) {
      final ackText = sheet!.acknowledgedAt == null
          ? 'This audit has been acknowledged. It is locked from further edits.'
          : 'Acknowledged on ${AppDateUtils.formatDisplay(sheet!.acknowledgedAt!)}. This audit is now locked.';
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.greenTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(ackText, style: AppTextStyles.body13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  'Awaiting owner acknowledgement. You can still edit this audit until it is acknowledged.',
                  style: AppTextStyles.body13,
                ),
              ),
            ],
          ),
          AppButton(
            label: 'Edit Audit',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.ghost,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
