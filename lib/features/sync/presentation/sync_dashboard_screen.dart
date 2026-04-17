import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class SyncDashboardScreen extends ConsumerWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSyncAsync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.cloud_sync, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Offline Sync Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  pendingSyncAsync.when(
                    data: (count) {
                      return Column(
                        children: [
                          Text(
                            '$count records pending',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: count > 0 ? Colors.orange : Colors.green,
                                ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: count > 0
                                ? () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Syncing data...')),
                                    );
                                    await ref.read(syncServiceProvider).syncData();
                                    ref.invalidate(pendingSyncCountProvider);
                                  }
                                : null,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync Now'),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Failed Sync Records or History can go here
        ],
      ),
    );
  }
}
