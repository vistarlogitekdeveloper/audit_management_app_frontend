import 'package:flutter/material.dart';

import '../../admin_reports/screens/admin_reports_screen.dart';

/// Cluster Manager view of reports & analytics.
///
/// The dashboard endpoint already filters everything to the cluster's
/// projects, so reusing the admin reports screen here gives the cluster
/// manager the same charts/filters scoped to their cluster. Edit / export
/// affordances stay available because the admin reports screen has no
/// destructive actions — only client-side filtering and CSV export.
class ClusterReportsScreen extends StatelessWidget {
  const ClusterReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminReportsScreen();
  }
}
