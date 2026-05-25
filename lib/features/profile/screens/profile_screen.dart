import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(profileProvider).fetch();
      _hydrateFromUser();
    });
  }

  void _hydrateFromUser() {
    final user = ref.read(profileProvider).user ??
        ref.read(authProvider).currentUser;
    if (user == null || _initialized) return;
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _emailController.text = user.email;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(profileProvider);
    final user = provider.user ?? ref.watch(authProvider).currentUser;
    if (!_initialized && user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email;
      _initialized = true;
    }

    return LoadingOverlay(
      isLoading: provider.isLoading && user == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHero(
            title: 'Profile & settings',
            subtitle:
                'Update your contact info, change your password, and tune notification preferences.',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 18),
          if (user == null)
            const AppPanel(
              child: EmptyPanel(message: 'Loading your profile…'),
            )
          else ...[
            AppPanel(
              title: 'Profile info',
              icon: Icons.badge_outlined,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppHelpers.avatarColorByRole(user.role),
                          child: Text(
                            user.avatarInitials,
                            style: AppTextStyles.medium14
                                .copyWith(color: AppColors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: AppTextStyles.title16),
                              Text(
                                AppHelpers.roleLabel(user.role),
                                style: AppTextStyles.body12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppInput(
                      label: 'Name',
                      controller: _nameController,
                      validator: (v) =>
                          Validators.validateRequired(v, fieldName: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      label: 'Email',
                      controller: _emailController,
                      isReadOnly: true,
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      label: 'Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Save changes',
                        icon: Icons.save_outlined,
                        isLoading: provider.isLoading,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppPanel(
              title: 'Password',
              icon: Icons.lock_outline,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change your password to keep your account secure.',
                      style: AppTextStyles.body13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Change password',
                    icon: Icons.password_rounded,
                    variant: AppButtonVariant.ghost,
                    onPressed: _openPasswordDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppPanel(
              title: 'Preferences',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Email notifications'),
                    subtitle: const Text(
                        'Receive audit and action plan updates by email.'),
                    value: provider.emailNotifications,
                    onChanged: (v) =>
                        ref.read(profileProvider).setEmailNotifications(v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Push notifications'),
                    subtitle: const Text(
                        'Get reminders and alerts on this device.'),
                    value: provider.pushNotifications,
                    onChanged: (v) =>
                        ref.read(profileProvider).setPushNotifications(v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String>(
                    label: 'Language',
                    value: provider.language,
                    items: const [
                      DropdownMenuItem(
                          value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      DropdownMenuItem(
                          value: 'Marathi', child: Text('Marathi')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(profileProvider).setLanguage(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppPanel(
              title: 'About',
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AboutLine(
                    label: 'App version',
                    value: '1.0.0',
                  ),
                  _AboutLine(
                    label: 'Terms of Service',
                    value: 'Tap to read the latest terms',
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ),
                  _AboutLine(
                    label: 'Privacy Policy',
                    value: 'How we handle your data',
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      variant: AppButtonVariant.danger,
                      onPressed: _logout,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await ref.read(profileProvider).save(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (!mounted) return;
      AppHelpers.showSuccessSnackbar(context, 'Profile updated.');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }

  Future<void> _openPasswordDialog() async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Change password')),
              IconButton(
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(
                  label: 'New password',
                  controller: newCtrl,
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 12),
                AppInput(
                  label: 'Confirm new password',
                  controller: confirmCtrl,
                  obscureText: true,
                  validator: (v) {
                    if (v != newCtrl.text) return 'Passwords do not match';
                    return Validators.validatePassword(v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setStateDialog(() => submitting = true);
                      try {
                        await ref
                            .read(profileProvider)
                            .changePassword(newCtrl.text);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      } catch (e) {
                        setStateDialog(() => submitting = false);
                        if (!dialogContext.mounted) return;
                        AppHelpers.showErrorSnackbar(
                          dialogContext,
                          AppHelpers.readableError(e),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      AppHelpers.showSuccessSnackbar(context, 'Password updated.');
    }
  }

  Future<void> _logout() async {
    final confirm = await AppHelpers.showConfirmationDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.danger,
    );
    if (!confirm || !mounted) return;
    await ref.read(authProvider).logout();
    if (mounted) context.go('/login');
  }
}

class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.medium13),
                Text(value, style: AppTextStyles.body12),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
