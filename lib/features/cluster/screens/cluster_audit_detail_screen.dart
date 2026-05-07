import 'package:flutter/material.dart';

import '../../report/screens/audit_report_screen.dart';

/// Cluster Manager view of an audit report. Reuses the shared report
/// screen — it is already read-only and has no role-specific affordances.
class ClusterAuditDetailScreen extends StatelessWidget {
  const ClusterAuditDetailScreen({super.key, required this.auditId});

  final String auditId;

  @override
  Widget build(BuildContext context) {
    return AuditReportScreen(auditId: auditId);
  }
}
