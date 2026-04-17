import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/db/app_database.dart';
import '../providers/audit_execution_provider.dart';

class AuditExecutionScreen extends ConsumerStatefulWidget {
  final String auditPlanId;

  const AuditExecutionScreen({super.key, required this.auditPlanId});

  @override
  ConsumerState<AuditExecutionScreen> createState() => _AuditExecutionScreenState();
}

class _AuditExecutionScreenState extends ConsumerState<AuditExecutionScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(auditQuestionsNotifierProvider(widget.auditPlanId));
    final responsesAsync = ref.watch(auditResponsesNotifierProvider(widget.auditPlanId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Execute Audit'),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions for this audit.'));
          }

          final responsesMap = <String, AuditResponse>{};
          if (responsesAsync.value != null) {
            for (var r in responsesAsync.value!) {
              responsesMap[r.questionId] = r;
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final response = responsesMap[question.id!];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${question.questionText}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (question.isRequired)
                            const Text('*', style: TextStyle(color: Colors.red, fontSize: 18))
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'PASS', label: Text('PASS'), icon: Icon(Icons.check)),
                          ButtonSegment(value: 'FAIL', label: Text('FAIL'), icon: Icon(Icons.close)),
                          ButtonSegment(value: 'NA', label: Text('N/A'), icon: Icon(Icons.remove)),
                        ],
                        selected: {response?.status ?? 'NA'},
                        onSelectionChanged: (Set<String> newSelection) {
                          _handleStatusChange(question.id!, newSelection.first, response);
                        },
                      ),
                      if (response?.status == 'FAIL') ...[
                        const SizedBox(height: 16),
                        _buildFailActions(question.id!, response),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _handleStatusChange(String questionId, String newStatus, AuditResponse? currentResponse) {
    ref.read(auditResponsesNotifierProvider(widget.auditPlanId).notifier).saveResponse(
      auditPlanId: widget.auditPlanId,
      questionId: questionId,
      status: newStatus,
      remarks: currentResponse?.remarks,
      imagePath: currentResponse?.imagePath,
    );
  }

  Widget _buildFailActions(String questionId, AuditResponse? response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: response?.remarks,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Enter reason for failure',
                ),
                onChanged: (val) {
                  ref.read(auditResponsesNotifierProvider(widget.auditPlanId).notifier).saveResponse(
                        auditPlanId: widget.auditPlanId,
                        questionId: questionId,
                        status: 'FAIL',
                        remarks: val,
                        imagePath: response?.imagePath,
                      );
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                response?.imagePath != null ? Icons.image : Icons.add_a_photo,
                color: response?.imagePath != null ? Colors.green : null,
              ),
              onPressed: () => _captureImage(questionId, response),
            ),
          ],
        ),
        if (response?.imagePath != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: response!.imagePath!.startsWith('http')
                ? Image.network(response.imagePath!, fit: BoxFit.cover)
                : Image.file(File(response.imagePath!), fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showActionPlanDialog(response?.clientTempId ?? ''),
          icon: const Icon(Icons.add_task),
          label: const Text('Create Action Plan'),
        ),
      ],
    );
  }

  Future<void> _captureImage(String questionId, AuditResponse? response) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ref.read(auditResponsesNotifierProvider(widget.auditPlanId).notifier).saveResponse(
            auditPlanId: widget.auditPlanId,
            questionId: questionId,
            status: 'FAIL',
            remarks: response?.remarks,
            imagePath: image.path,
          );
    }
  }

  void _showActionPlanDialog(String auditResponseId) {
    if (auditResponseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for response to save first.')),
      );
      return;
    }

    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Action Plan'),
          content: TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (descController.text.isNotEmpty) {
                  ref.read(actionPlansNotifierProvider(widget.auditPlanId).notifier).saveActionPlan(
                        auditResponseId: auditResponseId,
                        description: descController.text,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Action Plan created offline')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
