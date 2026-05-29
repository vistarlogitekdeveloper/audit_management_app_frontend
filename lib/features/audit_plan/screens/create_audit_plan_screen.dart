import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../models/audit_plan_model.dart';
import '../providers/audit_plan_provider.dart';

class CreateAuditPlanScreen extends ConsumerStatefulWidget {
  const CreateAuditPlanScreen({super.key});

  @override
  ConsumerState<CreateAuditPlanScreen> createState() =>
      _CreateAuditPlanScreenState();
}

class _CreateAuditPlanScreenState extends ConsumerState<CreateAuditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  ProjectLookupModel? _selectedProject;
  String? _selectedProjectInchargeId;
  String? _selectedClusterManagerId;
  String? _selectedAuditorId;
  DateTime? _auditDate;
  final _locationController = TextEditingController();
  final _remarksController = TextEditingController();
  final _auditDateController = TextEditingController();
  String? _lastReportedLookupError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(auditPlanProvider).bootstrap());
  }

  @override
  void dispose() {
    _locationController.dispose();
    _remarksController.dispose();
    _auditDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(auditPlanProvider);
    final wide = MediaQuery.of(context).size.width > 950;

    final lookupError = provider.lookupsError;
    if (lookupError != null && lookupError != _lastReportedLookupError) {
      _lastReportedLookupError = lookupError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppHelpers.showErrorSnackbar(
          context,
          'Could not load assignees: $lookupError',
        );
      });
    } else if (lookupError == null) {
      _lastReportedLookupError = null;
    }

    return LoadingOverlay(
      isLoading: provider.isLoading || provider.lookupsLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: 'Create audit plan',
            subtitle:
                'Schedule audits, assign ownership, and notify the right stakeholders from one focused workflow.',
            icon: Icons.add_task_rounded,
            action: FilledButton.icon(
              onPressed: () => _submit(context, provider, 'released'),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Release plan'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _planForm(provider)),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: _sidePanel(provider)),
              ],
            )
          else ...[
            _planForm(provider),
            const SizedBox(height: 18),
            _sidePanel(provider),
          ],
        ],
      ),
    );
  }

  Widget _planForm(AuditPlanProvider provider) {
    return AppPanel(
      title: 'Audit plan details',
      icon: Icons.assignment_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdown<ProjectLookupModel>(
              label: 'Project',
              value: _selectedProject,
              items:
                  provider.projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project,
                          child: Text(project.name),
                        ),
                      )
                      .toList(),
              validator:
                  (value) => value == null ? 'Project is required' : null,
              onChanged: (value) {
                setState(() {
                  _selectedProject = value;
                  _selectedProjectInchargeId = _matchUserId(
                    provider.projectIncharges,
                    value?.inchargeId,
                  );
                  _selectedClusterManagerId = _matchUserId(
                    provider.clusterManagers,
                    value?.clusterManagerId,
                  );
                  _locationController.text = value?.location ?? '';
                });
              },
            ),
            const SizedBox(height: 14),
            _userDropdown(
              label: 'Project Incharge',
              users: provider.projectIncharges,
              value: _selectedProjectInchargeId,
              onChanged:
                  (value) => setState(() => _selectedProjectInchargeId = value),
            ),
            const SizedBox(height: 14),
            _userDropdown(
              label: 'Cluster Manager',
              users: provider.clusterManagers,
              value: _selectedClusterManagerId,
              onChanged:
                  (value) => setState(() => _selectedClusterManagerId = value),
            ),
            const SizedBox(height: 14),
            _userDropdown(
              label: 'Assign Auditor',
              users: provider.auditors,
              value: _selectedAuditorId,
              onChanged: (value) => setState(() => _selectedAuditorId = value),
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'Audit Date',
              controller: _auditDateController,
              isReadOnly: true,
              validator: (_) => Validators.validateFutureDate(_auditDate),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (selected != null) {
                  setState(() {
                    _auditDate = selected;
                    _auditDateController.text =
                        AppDateUtils.formatDisplay(selected);
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'Location',
              controller: _locationController,
              validator:
                  (value) =>
                      Validators.validateRequired(value, fieldName: 'Location'),
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'Remarks',
              controller: _remarksController,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Save as Draft',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => _submit(context, provider, 'draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Release Audit Plan',
                    onPressed: () => _submit(context, provider, 'released'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidePanel(AuditPlanProvider provider) {
    return Column(
      children: [
        AppPanel(
          title: 'Release notifications',
          icon: Icons.mark_email_unread_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmailLine(
                'Project Incharge',
                _selectedUserLabel(
                  provider.projectIncharges,
                  _selectedProjectInchargeId,
                  fallbackName: _selectedProject?.inchargeName,
                  fallbackEmail: _selectedProject?.inchargeEmail,
                ),
              ),
              _EmailLine(
                'Cluster Manager',
                _selectedUserLabel(
                  provider.clusterManagers,
                  _selectedClusterManagerId,
                  fallbackName: _selectedProject?.clusterManagerName,
                  fallbackEmail: _selectedProject?.clusterManagerEmail,
                ),
              ),
              const _EmailLine('Management Team', 'management@vistar.com'),
              const SizedBox(height: 8),
              Text(
                'Reminder email auto-sent 2 days before audit date',
                style: AppTextStyles.body11,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    AuditPlanProvider provider,
    String status,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    await provider.createPlan({
      'projectId': _selectedProject!.id,
      'projectName': _selectedProject!.name,
      'projectInchargeId': _selectedProjectInchargeId,
      'projectIncharge': _selectedUserName(
        provider.projectIncharges,
        _selectedProjectInchargeId,
        fallbackName: _selectedProject!.inchargeName,
      ),
      'clusterManagerId': _selectedClusterManagerId,
      'clusterManager': _selectedUserName(
        provider.clusterManagers,
        _selectedClusterManagerId,
        fallbackName: _selectedProject!.clusterManagerName,
      ),
      'auditorId': _selectedAuditorId,
      'auditorName':
          _findUser(provider.auditors, _selectedAuditorId)?.name ?? '',
      'auditDate': _dateForApi(_auditDate!),
      'location': _locationController.text.trim(),
      'remarks': _remarksController.text.trim(),
      'status': status,
    });
    if (!context.mounted) return;

    if (status == 'released') {
      await _showReleasedSuccessDialog(context);
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      // ignore: dead_code
    } else {
      AppHelpers.showSuccessSnackbar(
        context,
        'Audit plan saved as draft.',
      );
    }
  }

  Future<void> _showReleasedSuccessDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        compact: true,
        icon: Icons.send_rounded,
        iconColor: AppColors.primary,
        title: 'Audit Plan Released!',
        message:
            'Released successfully. Notifications sent to the auditor, project incharge, and cluster manager.',
        actions: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Stay on the create plan form to create another
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: const Text('Create Another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/admin/calendar');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: const Text('View Calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userDropdown({
    required String label,
    required List<UserLookupModel> users,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final items = users
        .where((u) => u.id.isNotEmpty)
        .map((u) => DropdownMenuItem(value: u.id, child: Text(u.label)))
        .toList();
    final hasMatch = value != null && items.any((i) => i.value == value);

    return AppDropdown<String>(
      label: label,
      hint: items.isEmpty
          ? 'No active users with this role — ask admin to create one'
          : 'Select $label',
      value: hasMatch ? value : null,
      items: items,
      validator: (v) => v == null ? '$label is required' : null,
      onChanged: items.isEmpty ? null : onChanged,
    );
  }

  String? _matchUserId(List<UserLookupModel> users, String? id) {
    if (id == null || id.isEmpty) return null;
    return users.any((u) => u.id == id) ? id : null;
  }

  String _selectedUserLabel(
    List<UserLookupModel> users,
    String? id, {
    String? fallbackName,
    String? fallbackEmail,
  }) {
    final user = _findUser(users, id);
    if (user != null) return user.label;
    final name = fallbackName ?? '';
    final email = fallbackEmail ?? '';
    if (name.isEmpty) return '-';
    return email.isEmpty ? name : '$name - $email';
  }

  String _selectedUserName(
    List<UserLookupModel> users,
    String? id, {
    required String fallbackName,
  }) {
    return _findUser(users, id)?.name ?? fallbackName;
  }

  UserLookupModel? _findUser(List<UserLookupModel> users, String? id) {
    if (id == null) return null;
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  String _dateForApi(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}

class _EmailLine extends StatelessWidget {
  const _EmailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body13)),
          Text(value, style: AppTextStyles.body12),
        ],
      ),
    );
  }
}
