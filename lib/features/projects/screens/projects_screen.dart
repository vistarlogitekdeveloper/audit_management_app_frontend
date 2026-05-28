import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_sheet_header.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../../audit_plan/models/audit_plan_model.dart';
import '../../audit_plan/providers/audit_plan_provider.dart';
import '../models/project_model.dart';
import '../providers/project_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(projectAdminProvider).fetchProjects());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(projectAdminProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 760;

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: 'Project management',
            subtitle:
                'Maintain the project register: clients, locations, project incharges, and cluster managers.',
            icon: Icons.location_city_outlined,
            action: FilledButton.icon(
              onPressed: () => _showProjectSheet(context),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Add project'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppPanel(
            child: AppInput(
              label: 'Search projects',
              hint: 'Search by name, location or client',
              controller: _searchController,
              suffixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) =>
                  ref.read(projectAdminProvider).setSearch(value),
            ),
          ),
          const SizedBox(height: 14),
          if (provider.error != null)
            AppPanel(
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppHelpers.readableError(provider.error!),
                      style: AppTextStyles.body13,
                    ),
                  ),
                  AppButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.ghost,
                    onPressed: () =>
                        ref.read(projectAdminProvider).fetchProjects(),
                  ),
                ],
              ),
            )
          else if (provider.filtered.isEmpty)
            const AppPanel(child: EmptyPanel(message: 'No projects found.'))
          else
            isMobile
                ? Column(
                    children: provider.filtered
                        .map((project) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProjectCard(
                                  project: project, onAction: _onAction),
                            ))
                        .toList(),
                  )
                : AppPanel(
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(AppColors.greyTint),
                        columns: const [
                          DataColumn(label: Text('Project')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Client')),
                          DataColumn(label: Text('Incharge')),
                          DataColumn(label: Text('Cluster Mgr')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: provider.filtered
                            .map((p) => _projectRow(p))
                            .toList(),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  DataRow _projectRow(ProjectAdminModel project) {
    return DataRow(cells: [
      DataCell(Row(children: [
        const Icon(Icons.business_outlined,
            size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(project.name, style: AppTextStyles.medium13),
      ])),
      DataCell(Text(project.location, style: AppTextStyles.body13)),
      DataCell(Text(
          project.clientName.isEmpty ? '-' : project.clientName,
          style: AppTextStyles.body13)),
      DataCell(Text(
          project.inchargeName.isEmpty ? '-' : project.inchargeName,
          style: AppTextStyles.body13)),
      DataCell(Text(
          project.clusterManagerName.isEmpty
              ? '-'
              : project.clusterManagerName,
          style: AppTextStyles.body13)),
      DataCell(StatusPill(status: project.isActive ? 'Active' : 'Inactive')),
      DataCell(_actionMenu(project)),
    ]);
  }

  Widget _actionMenu(ProjectAdminModel project) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (value) => _onAction(value, project),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (project.isActive)
          const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
      ],
    );
  }

  Future<void> _onAction(String action, ProjectAdminModel project) async {
    if (action == 'edit') {
      _showProjectSheet(context, project: project);
    } else if (action == 'deactivate') {
      final confirm = await AppHelpers.showConfirmationDialog(
        context: context,
        title: 'Deactivate project',
        message:
            'Are you sure you want to deactivate ${project.name}? It will be hidden from new audit plans.',
        confirmLabel: 'Deactivate',
        confirmColor: AppColors.danger,
      );
      if (!confirm || !mounted) return;
      try {
        await ref.read(projectAdminProvider).deactivateProject(project.id);
        if (!mounted) return;
        AppHelpers.showSuccessSnackbar(context, 'Project deactivated.');
      } catch (e) {
        if (!mounted) return;
        AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
      }
    }
  }

  Future<void> _showProjectSheet(BuildContext context,
      {ProjectAdminModel? project}) async {
    final auditPlan = ref.read(auditPlanProvider);
    final incharges = auditPlan.projectIncharges;
    final clusters = auditPlan.clusterManagers;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: _ProjectForm(
          existing: project,
          incharges: incharges,
          clusterManagers: clusters,
          onSubmit: (payload) async {
            try {
              if (project == null) {
                await ref.read(projectAdminProvider).createProject(payload);
                if (!sheetContext.mounted) return;
                AppHelpers.showSuccessSnackbar(
                    sheetContext, 'Project created.');
              } else {
                await ref
                    .read(projectAdminProvider)
                    .updateProject(project.id, payload);
                if (!sheetContext.mounted) return;
                AppHelpers.showSuccessSnackbar(
                    sheetContext, 'Project updated.');
              }
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            } catch (e) {
              if (!sheetContext.mounted) return;
              AppHelpers.showErrorSnackbar(
                  sheetContext, AppHelpers.readableError(e));
            }
          },
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onAction});

  final ProjectAdminModel project;
  final Future<void> Function(String, ProjectAdminModel) onAction;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: AppTextStyles.medium14),
                    if (project.location.isNotEmpty)
                      Text(project.location, style: AppTextStyles.body12),
                  ],
                ),
              ),
              StatusPill(status: project.isActive ? 'Active' : 'Inactive'),
            ],
          ),
          const SizedBox(height: 10),
          if (project.clientName.isNotEmpty)
            _LineRow(
                icon: Icons.handshake_outlined, label: project.clientName),
          if (project.inchargeName.isNotEmpty)
            _LineRow(
                icon: Icons.person_outline, label: project.inchargeName),
          if (project.clusterManagerName.isNotEmpty)
            _LineRow(
                icon: Icons.account_tree_outlined,
                label: project.clusterManagerName),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.ghost,
                onPressed: () => onAction('edit', project),
              ),
              if (project.isActive) ...[
                const SizedBox(width: 8),
                AppButton(
                  label: 'Deactivate',
                  icon: Icons.block_rounded,
                  variant: AppButtonVariant.danger,
                  onPressed: () => onAction('deactivate', project),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.body12)),
        ],
      ),
    );
  }
}

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({
    this.existing,
    required this.incharges,
    required this.clusterManagers,
    required this.onSubmit,
  });

  final ProjectAdminModel? existing;
  final List<UserLookupModel> incharges;
  final List<UserLookupModel> clusterManagers;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _client;
  String? _inchargeId;
  String? _clusterId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _location = TextEditingController(text: widget.existing?.location ?? '');
    _client = TextEditingController(text: widget.existing?.clientName ?? '');
    _inchargeId = widget.existing?.inchargeId.isEmpty ?? true
        ? null
        : widget.existing!.inchargeId;
    _clusterId = widget.existing?.clusterManagerId.isEmpty ?? true
        ? null
        : widget.existing!.clusterManagerId;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetHeader(title: isEdit ? 'Edit project' : 'Add project'),
            const SizedBox(height: 14),
            AppInput(
              label: 'Project name',
              controller: _name,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: 'Project name'),
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Location',
              controller: _location,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: 'Location'),
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Client (optional)',
              controller: _client,
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: 'Project Incharge',
              value: _inchargeId,
              items: _userItems(widget.incharges),
              validator: (v) => Validators.validateSelection(v,
                  fieldName: 'Project Incharge'),
              onChanged: (value) => setState(() => _inchargeId = value),
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: 'Cluster Manager',
              value: _clusterId,
              items: _userItems(widget.clusterManagers),
              validator: (v) => Validators.validateSelection(v,
                  fieldName: 'Cluster Manager'),
              onChanged: (value) => setState(() => _clusterId = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: isEdit ? 'Save changes' : 'Create project',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _userItems(List<UserLookupModel> users) {
    return users
        .where((u) => u.id.isNotEmpty)
        .map((u) => DropdownMenuItem(value: u.id, child: Text(u.label)))
        .toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'client_name': _client.text.trim().isEmpty ? null : _client.text.trim(),
      'project_incharge_id': _inchargeId,
      'cluster_manager_id': _clusterId,
      'is_active': true,
    };
    try {
      await widget.onSubmit(payload);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
