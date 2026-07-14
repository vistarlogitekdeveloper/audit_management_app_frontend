import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/brand.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Restore the "Remember me" state on first frame. Reading via
    // ref.read is safe in initState because SharedPreferences was
    // already loaded synchronously before runApp().
    final prefs = ref.read(sharedPreferencesProvider);
    _rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
    if (_rememberMe) {
      _emailController.text =
          prefs.getString(AppConstants.rememberedEmailKey) ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _persistRememberMe(String email) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (_rememberMe) {
      await prefs.setBool(AppConstants.rememberMeKey, true);
      await prefs.setString(AppConstants.rememberedEmailKey, email);
    } else {
      await prefs.remove(AppConstants.rememberMeKey);
      await prefs.remove(AppConstants.rememberedEmailKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientCanvas()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final horizontalPadding = isWide ? 40.0 : 20.0;
                final verticalPadding = isWide ? 32.0 : 20.0;
                final availableHeight =
                    constraints.maxHeight - (verticalPadding * 2);
                final double? panelHeight =
                    isWide
                        ? availableHeight.clamp(560.0, 680.0).toDouble()
                        : null;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1080,
                        minHeight: panelHeight ?? 0,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 60,
                              offset: const Offset(0, 32),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child:
                              isWide
                                  ? SizedBox(
                                    height: panelHeight,
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          flex: 105,
                                          child: _BrandPanel(),
                                        ),
                                        Expanded(
                                          flex: 95,
                                          child: Container(
                                            color: AppColors.bgRaised,
                                            child: Center(
                                              child: SingleChildScrollView(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 24,
                                                    ),
                                                child: _LoginFormPanel(
                                                  formKey: _formKey,
                                                  emailController:
                                                      _emailController,
                                                  passwordController:
                                                      _passwordController,
                                                  obscure: _obscure,
                                                  isLoading: auth.isLoading,
                                                  rememberMe: _rememberMe,
                                                  onToggleRemember: (v) {
                                                    setState(
                                                      () => _rememberMe = v,
                                                    );
                                                  },
                                                  onTogglePassword: () {
                                                    setState(
                                                      () =>
                                                          _obscure = !_obscure,
                                                    );
                                                  },
                                                  onSubmit: _submitLogin,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Container(
                                    color: AppColors.bgRaised,
                                    child: _LoginFormPanel(
                                      formKey: _formKey,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      obscure: _obscure,
                                      isLoading: auth.isLoading,
                                      showMobileBrand: true,
                                      rememberMe: _rememberMe,
                                      onToggleRemember: (v) {
                                        setState(() => _rememberMe = v);
                                      },
                                      onTogglePassword: () {
                                        setState(() => _obscure = !_obscure);
                                      },
                                      onSubmit: _submitLogin,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      var result = await ref.read(authProvider).login(email, password);
      // The email maps to several roles — ask which one to continue as, then
      // log in again with that role.
      if (result.requiresRoleSelection) {
        if (!mounted) return;
        final role = await _promptRoleSelection(result.roles);
        if (role == null || !mounted) return; // cancelled — stay on login
        result = await ref.read(authProvider).login(email, password, role: role);
      }
      if (result.requiresRoleSelection) {
        // Defensive: the second call should always yield a session.
        if (!mounted) return;
        AppHelpers.showErrorSnackbar(context, 'Please try signing in again.');
        return;
      }
      // Persist (or clear) the remembered email only on a successful
      // login — we never want to "remember" an email the user fat-
      // fingered into a failing attempt.
      await _persistRememberMe(email);
      if (!mounted) return;
      context.go(ref.read(authProvider).homeRouteForRole());
    } catch (error) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(error));
    }
  }

  /// Shows the role picker for a multi-role email. Returns the chosen backend
  /// role string (e.g. `project_owner`) or null if the user dismissed it.
  Future<String?> _promptRoleSelection(List<String> roles) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.line),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose a role', style: AppTextStyles.title18),
                  const SizedBox(height: 6),
                  Text(
                    'This account has more than one role. Select the one you '
                    'want to continue as.',
                    style: AppTextStyles.body13,
                  ),
                  const SizedBox(height: 18),
                  ...roles.map((role) {
                    final normalized = AppConstants.normalizeRole(role);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoleChoiceTile(
                        label: AppHelpers.roleLabel(normalized),
                        icon: _roleIcon(normalized),
                        onTap: () =>
                            Navigator.of(dialogContext).pop(role),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.medium13
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _roleIcon(String normalizedRole) {
    switch (normalizedRole) {
      case AppConstants.roleAdmin:
        return Icons.admin_panel_settings_outlined;
      case AppConstants.roleAuditor:
        return Icons.assignment_outlined;
      case AppConstants.roleProjectOwner:
        return Icons.reviews_outlined;
      case AppConstants.roleClusterManager:
        return Icons.hub_outlined;
      default:
        return Icons.badge_outlined;
    }
  }
}

/// A tappable role option in the multi-role login picker.
class _RoleChoiceTile extends StatelessWidget {
  const _RoleChoiceTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.30)),
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.medium14),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.isLoading,
    required this.rememberMe,
    required this.onToggleRemember,
    required this.onTogglePassword,
    required this.onSubmit,
    this.showMobileBrand = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool isLoading;
  final bool rememberMe;
  final ValueChanged<bool> onToggleRemember;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(showMobileBrand ? 24 : 40),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMobileBrand) ...[
              const _CompactBrandHeader(),
              const SizedBox(height: 28),
            ],
            Text('Sign in', style: AppTextStyles.headline22),
            const SizedBox(height: 6),
            Text(
              'Access audit plans, reviews, action items, and reports.',
              style: AppTextStyles.body13,
            ),
            const SizedBox(height: 28),
            AppInput(
              label: 'Email address',
              hint: 'name@company.com',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Password',
              hint: 'Enter your password',
              controller: passwordController,
              obscureText: obscure,
              validator: Validators.validatePassword,
              suffixIcon: IconButton(
                tooltip: obscure ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _RememberMeToggle(
                  value: rememberMe,
                  onChanged: onToggleRemember,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.medium13.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppButton(
              label: isLoading ? 'Signing in' : 'Sign in securely',
              icon: isLoading ? null : Icons.login_rounded,
              isLoading: isLoading,
              isFullWidth: true,
              onPressed: isLoading ? null : onSubmit,
            ),
            // Dev-only SMTP probe — compiled out of release/profile builds
            // so production users can never trigger backend test emails.
            if (kDebugMode) ...[
              const SizedBox(height: 14),
              const _TestSmtpButton(),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Remember me" toggle — a hand-rolled checkbox + label so the
/// affordance sits comfortably on the dark surface (Material's
/// Checkbox label spacing reads cramped against the form). Tapping
/// either the box or the label flips the value.
class _RememberMeToggle extends StatelessWidget {
  const _RememberMeToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.line2,
                  width: 1.4,
                ),
                boxShadow:
                    value
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                        : null,
              ),
              child:
                  value
                      ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.white,
                      )
                      : null,
            ),
            const SizedBox(width: 9),
            Text(
              'Remember me',
              style: AppTextStyles.medium13.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// REMOVE BEFORE FINAL PRODUCTION DEPLOYMENT
class _TestSmtpButton extends StatefulWidget {
  const _TestSmtpButton();

  @override
  State<_TestSmtpButton> createState() => _TestSmtpButtonState();
}

class _TestSmtpButtonState extends State<_TestSmtpButton> {
  bool _loading = false;

  Future<void> _sendTest() async {
    setState(() => _loading = true);
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final resp = await dio.get('/test-smtp');
      final data = resp.data is Map ? resp.data as Map : <String, dynamic>{};
      final ok = data['data']?['ok'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Test email sent to Flutter.developer@vistarlogitek.com'
                : 'SMTP failed: ${data['data']?['error'] ?? 'unknown error'}',
          ),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _sendTest,
      icon:
          _loading
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.email_outlined, size: 16),
      label: Text(
        _loading ? 'Sending…' : '[DEV] Test SMTP email',
        style: AppTextStyles.medium13,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Stack(
        children: [
          // Radial brand glows (purple, pink, amber).
          const Positioned.fill(child: _BrandGlows()),
          // Huge rotated faint S behind the content.
          Positioned(
            right: -120,
            top: -40,
            bottom: -40,
            child: Transform.rotate(
              angle: 6 * 3.1415926 / 180,
              child: Opacity(
                opacity: 0.16,
                child: SizedBox(
                  width: 620,
                  child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            // Fill the panel height so the Spacers distribute nicely, but
            // scroll instead of overflowing when the window is too short.
            child: LayoutBuilder(
              builder:
                  (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight.isFinite
                                ? constraints.maxHeight
                                : 0,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Image.asset(
                                    kWordmarkAsset,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Pitch headline with a single ribbon-gradient accent word.
                            RichText(
                              text: TextSpan(
                                style: AppTextStyles.headline22.copyWith(
                                  fontSize: 32,
                                  height: 1.18,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  const TextSpan(text: 'Audit '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: RibbonText(
                                      'control',
                                      style: AppTextStyles.headline22.copyWith(
                                        fontSize: 32,
                                        height: 1.18,
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' that stays clear under pressure.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Plan audits, capture findings, track action plans, and keep every stakeholder aligned from one workspace.',
                              style: AppTextStyles.body14.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _AuditPreview(),
                            const Spacer(),
                            Row(
                              children: [
                                _MetricPill(
                                  icon: Icons.verified_outlined,
                                  label: 'Live status',
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 10),
                                _MetricPill(
                                  icon: Icons.schedule_outlined,
                                  label: 'Due tracking',
                                  color: AppColors.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandGlows extends StatelessWidget {
  const _BrandGlows();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.8),
                radius: 0.8,
                colors: [
                  AppColors.ribbonViolet.withValues(alpha: 0.32),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.9),
                radius: 0.9,
                colors: [
                  AppColors.ribbonPink.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.4, -1.0),
                radius: 0.7,
                colors: [
                  AppColors.ribbonAmber.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vistar Audit', style: AppTextStyles.title18),
            const SizedBox(height: 2),
            Text('Management console', style: AppTextStyles.body12),
          ],
        ),
      ],
    );
  }
}

class _AuditPreview extends StatelessWidget {
  const _AuditPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface2.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line2),
      ),
      child: const Column(
        children: [
          _PreviewRow(
            icon: Icons.playlist_add_check_outlined,
            title: 'Warehouse Safety Audit',
            subtitle: '12 checkpoints ready',
          ),
          SizedBox(height: 14),
          _PreviewRow(
            icon: Icons.rate_review_outlined,
            title: 'Owner review',
            subtitle: '3 findings pending',
          ),
          SizedBox(height: 14),
          _PreviewRow(
            icon: Icons.trending_up_outlined,
            title: 'Pass rate',
            subtitle: 'Improved this cycle',
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
            ),
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.medium13),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.body12),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.medium12.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
