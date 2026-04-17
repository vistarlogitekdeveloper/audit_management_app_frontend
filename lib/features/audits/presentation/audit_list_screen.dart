import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/audit_provider.dart';

class AuditListScreen extends ConsumerStatefulWidget {
  const AuditListScreen({super.key});

  @override
  ConsumerState<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends ConsumerState<AuditListScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final auditsAsync = ref.watch(auditPlansNotifierProvider(statusFilter: _selectedFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Plans'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: auditsAsync.when(
              data: (audits) {
                if (audits.isEmpty) {
                  return const Center(child: Text('No audit plans found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: audits.length,
                  itemBuilder: (context, index) {
                    final audit = audits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          audit.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(audit.description ?? 'No description provided'),
                            const SizedBox(height: 8),
                            _buildStatusChip(audit.status),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to Execution
                          if (audit.id != null) {
                            context.push('/audits/${audit.id}');
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Planned', 'PLANNED'),
          const SizedBox(width: 8),
          _buildFilterChip('Ongoing', 'ONGOING'),
          const SizedBox(width: 8),
          _buildFilterChip('Submitted', 'SUBMITTED'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : null;
        });
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PLANNED':
        color = Colors.blue;
        break;
      case 'ONGOING':
        color = Colors.orange;
        break;
      case 'SUBMITTED':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
