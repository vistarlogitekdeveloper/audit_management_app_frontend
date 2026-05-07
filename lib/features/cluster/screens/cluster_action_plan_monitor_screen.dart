import 'package:flutter/material.dart';

import '../../action_plan_tracker/screens/action_plan_tracker_screen.dart';

/// Cluster Manager view of action plans. The tracker accepts a
/// [readOnly] flag that hides the Edit affordance and routes plan taps
/// to the cluster audit detail screen.
class ClusterActionPlanMonitorScreen extends StatelessWidget {
  const ClusterActionPlanMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ActionPlanTrackerScreen(readOnly: true);
  }
}
