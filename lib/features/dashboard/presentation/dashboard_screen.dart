import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final syncCountAsync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: () {
              context.push('/sync-dashboard');
            },
            tooltip: 'Sync Center',
          ),
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            onPressed: () {
              context.push('/action-plans');
            },
            tooltip: 'Action Plans',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(auditStatsProvider);
          ref.invalidate(pendingSyncCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sync Status Card
            InkWell(
              onTap: () => context.push('/sync-dashboard'),
              child: _buildSyncCard(context, ref, syncCountAsync),
            ),
            const SizedBox(height: 16),
            
            // Summary Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () => context.push('/audits'),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View Audits'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (data) => _buildSummaryGrid(context, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context, WidgetRef ref, AsyncValue<int> syncCountAsync) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Sync Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                syncCountAsync.when(
                  data: (count) => Text(
                    count > 0 ? '$count items pending sync' : 'All items synced',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                  loading: () => const Text('Calculating...'),
                  error: (_, __) => const Text('Error calculating sync'),
                ),
              ],
            ),
            Icon(
              Icons.cloud_sync,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, Map<String, dynamic> data) {
    final int totalAudits = data['totalAudits'] ?? 0;
    final int ongoing = data['ongoingAudits'] ?? 0;
    final int completed = data['completedAudits'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          context,
          title: 'Total Audits',
          value: totalAudits.toString(),
          icon: Icons.assessment,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Ongoing',
          value: ongoing.toString(),
          icon: Icons.loop,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Completed',
          value: completed.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
