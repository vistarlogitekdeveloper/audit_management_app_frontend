import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  static const _roleFilters = <_RoleTab>[
    _RoleTab('All', ''),
    _RoleTab('Admins', 'admin'),
    _RoleTab('Auditors', 'auditor'),
    _RoleTab('Owners', 'project_owner'),
    _RoleTab('Cluster Mgrs', 'cluster_manager'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userProvider).fetchUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(userProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 760;

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: 'User management',
            subtitle:
                'Create accounts, assign roles, and control workspace access for your audit team.',
            icon: Icons.group_outlined,
            action: FilledButton.icon(
              onPressed: () => _showUserSheet(context),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add user'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roleFilters.map((tab) {
                    final selected = provider.roleFilter == tab.role;
                    return ChoiceChip(
                      label: Text(tab.label),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(userProvider).setRoleFilter(tab.role),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: AppTextStyles.medium13.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.32)
                              : AppColors.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                AppInput(
                  label: 'Search users',
                  hint: 'Search by name or email',
                  controller: _searchController,
                  suffixIcon: const Icon(Icons.search_rounded),
                  onChanged: (value) =>
                      ref.read(userProvider).setSearch(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (provider.error != null)
            AppPanel(
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
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
                    onPressed: () => ref.read(userProvider).fetchUsers(),
                  ),
                ],
              ),
            )
          else if (provider.filtered.isEmpty)
            const AppPanel(child: EmptyPanel(message: 'No users found.'))
          else
            isMobile
                ? Column(
                    children: provider.filtered
                        .map((user) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UserCard(user: user, onAction: _onAction),
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
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: provider.filtered
                            .map((user) => _userRow(user))
                            .toList(),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  DataRow _userRow(UserModel user) {
    return DataRow(cells: [
      DataCell(Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              AppHelpers.avatarColorByRole(_normalize(user.role)),
          child: Text(
            AppHelpers.getInitials(user.name),
            style:
                AppTextStyles.medium12.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(width: 10),
        Text(user.name, style: AppTextStyles.medium13),
      ])),
      DataCell(Text(user.email, style: AppTextStyles.body13)),
      DataCell(StatusPill(status: AppHelpers.roleLabel(_normalize(user.role)))),
      DataCell(Text(user.phone.isEmpty ? '-' : user.phone,
          style: AppTextStyles.body13)),
      DataCell(StatusPill(status: user.isActive ? 'Active' : 'Inactive')),
      DataCell(_actionMenu(user)),
    ]);
  }

  Widget _actionMenu(UserModel user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (value) => _onAction(value, user),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (user.isActive)
          const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
      ],
    );
  }

  Future<void> _onAction(String action, UserModel user) async {
    if (action == 'edit') {
      _showUserSheet(context, user: user);
    } else if (action == 'deactivate') {
      final confirm = await AppHelpers.showConfirmationDialog(
        context: context,
        title: 'Deactivate user',
        message:
            'Are you sure you want to deactivate ${user.name}? They will lose workspace access.',
        confirmLabel: 'Deactivate',
        confirmColor: AppColors.danger,
      );
      if (!confirm || !mounted) return;
      try {
        await ref.read(userProvider).deactivateUser(user.id);
        if (!mounted) return;
        AppHelpers.showSuccessSnackbar(context, 'User deactivated.');
      } catch (e) {
        if (!mounted) return;
        AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
      }
    }
  }

  String _normalize(String role) =>
      AppConstants.normalizeRole(role).isEmpty ? role : AppConstants.normalizeRole(role);

  Future<void> _showUserSheet(BuildContext context, {UserModel? user}) async {
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
        child: _UserForm(
          existing: user,
          onSubmit: (payload) async {
            try {
              if (user == null) {
                await ref.read(userProvider).createUser(payload);
                if (!sheetContext.mounted) return;
                AppHelpers.showSuccessSnackbar(
                    sheetContext, 'User created. Welcome email sent.');
              } else {
                await ref.read(userProvider).updateUser(user.id, payload);
                if (!sheetContext.mounted) return;
                AppHelpers.showSuccessSnackbar(sheetContext, 'User updated.');
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

class _RoleTab {
  const _RoleTab(this.label, this.role);
  final String label;
  final String role;
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onAction});

  final UserModel user;
  final Future<void> Function(String, UserModel) onAction;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppHelpers.avatarColorByRole(
                    AppConstants.normalizeRole(user.role)),
                child: Text(
                  AppHelpers.getInitials(user.name),
                  style:
                      AppTextStyles.medium12.copyWith(color: AppColors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.medium14),
                    Text(user.email, style: AppTextStyles.body12),
                  ],
                ),
              ),
              StatusPill(status: user.isActive ? 'Active' : 'Inactive'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(
                  status: AppHelpers.roleLabel(
                      AppConstants.normalizeRole(user.role))),
              if (user.phone.isNotEmpty)
                Text(user.phone, style: AppTextStyles.body12),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.ghost,
                onPressed: () => onAction('edit', user),
              ),
              if (user.isActive) ...[
                const SizedBox(width: 8),
                AppButton(
                  label: 'Deactivate',
                  icon: Icons.block_rounded,
                  variant: AppButtonVariant.danger,
                  onPressed: () => onAction('deactivate', user),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UserForm extends StatefulWidget {
  const _UserForm({this.existing, required this.onSubmit});

  final UserModel? existing;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _password = TextEditingController();
  String? _role;
  bool _submitting = false;

  static const _roleOptions = [
    ('admin', 'Admin'),
    ('auditor', 'Auditor'),
    ('project_owner', 'Project Owner'),
    ('cluster_manager', 'Cluster Manager'),
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _role = widget.existing?.role;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
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
            Text(isEdit ? 'Edit user' : 'Add user',
                style: AppTextStyles.title18),
            const SizedBox(height: 14),
            AppInput(
              label: 'Name',
              controller: _name,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: 'Name'),
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              isReadOnly: isEdit,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 12),
            if (!isEdit) ...[
              AppInput(
                label: 'Password',
                controller: _password,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Role',
                value: _role,
                items: _roleOptions
                    .map((entry) => DropdownMenuItem(
                          value: entry.$1,
                          child: Text(entry.$2),
                        ))
                    .toList(),
                validator: (v) =>
                    Validators.validateSelection(v, fieldName: 'Role'),
                onChanged: (value) => setState(() => _role = value),
              ),
              const SizedBox(height: 12),
            ],
            AppInput(
              label: 'Phone (optional)',
              controller: _phone,
              keyboardType: TextInputType.phone,
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
                    label: isEdit ? 'Save changes' : 'Create user',
                    isLoading: _submitting,
                    onPressed: () => _submit(isEdit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(bool isEdit) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
    };
    if (!isEdit) {
      payload['email'] = _email.text.trim();
      payload['password'] = _password.text;
      payload['role'] = _role;
    }
    try {
      await widget.onSubmit(payload);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
