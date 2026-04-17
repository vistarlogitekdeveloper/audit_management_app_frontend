import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/db/app_database.dart';
import '../../audits/providers/audit_execution_provider.dart';

class ActionPlansScreen extends ConsumerStatefulWidget {
  const ActionPlansScreen({super.key});

  @override
  ConsumerState<ActionPlansScreen> createState() => _ActionPlansScreenState();
}

class _ActionPlansScreenState extends ConsumerState<ActionPlansScreen> {
  @override
  Widget build(BuildContext context) {
    // We pass empty string to get all, in a real scenario we might have an API or provider that fetches all globally.
    // For now we'll use the provider we built but it requires an auditPlanId. 
    // Wait, the provider actionPlansNotifierProvider requires auditPlanId. Let's create a generic ActionPlansNotifier.
    
    // We can just watch from AppDatabase directly here for simplicity
    final db = ref.watch(appDatabaseProvider);
    final actionPlansStream = db.select(db.actionPlans).watch();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Plans'),
      ),
      body: StreamBuilder<List<ActionPlan>>(
        stream: actionPlansStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final plans = snapshot.data ?? [];
          if (plans.isEmpty) {
            return const Center(child: Text('No action plans.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(plan.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Status: ${plan.status}'),
                      if (plan.dueDate != null)
                        Text('Due: ${plan.dueDate.toString().split(' ').first}'),
                      if (plan.assignedTo != null)
                        Text('Assigned to: ${plan.assignedTo}'),
                      Text(plan.isSynced ? 'Synced \u2705' : 'Pending Sync \u23f3', 
                           style: TextStyle(color: plan.isSynced ? Colors.green : Colors.orange)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to edit screen or show dialog
                      _showEditDialog(plan);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(ActionPlan plan) {
    final assignController = TextEditingController(text: plan.assignedTo);
    final db = ref.read(appDatabaseProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign User'),
          content: TextField(
            controller: assignController,
            decoration: const InputDecoration(labelText: 'Assign to (Email/Name)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await (db.update(db.actionPlans)
                      ..where((t) => t.clientTempId.equals(plan.clientTempId)))
                    .write(ActionPlansCompanion(
                      assignedTo: drift.Value(assignController.text),
                      isSynced: const drift.Value(false), // Mark dirty for sync
                      updatedAt: drift.Value(DateTime.now()),
                    ));
                nav.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
