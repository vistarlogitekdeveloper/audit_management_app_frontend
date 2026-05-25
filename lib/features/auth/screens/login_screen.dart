import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_input.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = isWide ? 40.0 : 20.0;
            final verticalPadding = isWide ? 32.0 : 20.0;
            final availableHeight =
                constraints.maxHeight - (verticalPadding * 2);
            final double? panelHeight =
                isWide ? availableHeight.clamp(560.0, 680.0).toDouble() : null;

            return Stack(
              children: [
                const Positioned.fill(child: _LoginBackground()),
                Center(
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child:
                            isWide
                                ? SizedBox(
                                  height: panelHeight,
                                  child: Row(
                                    children: [
                                      const Expanded(child: _BrandPanel()),
                                      Expanded(
                                        child: Center(
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 24,
                                            ),
                                            child: _LoginFormPanel(
                                              formKey: _formKey,
                                              emailController: _emailController,
                                              passwordController:
                                                  _passwordController,
                                              obscure: _obscure,
                                              isLoading: auth.isLoading,
                                              onTogglePassword: () {
                                                setState(
                                                  () => _obscure = !_obscure,
                                                );
                                              },
                                              onSubmit: _submitLogin,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : _LoginFormPanel(
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  obscure: _obscure,
                                  isLoading: auth.isLoading,
                                  showMobileBrand: true,
                                  onTogglePassword: () {
                                    setState(() => _obscure = !_obscure);
                                  },
                                  onSubmit: _submitLogin,
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authProvider)
          .login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      context.go(ref.read(authProvider).homeRouteForRole());
    } catch (error) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(error));
    }
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    this.showMobileBrand = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(showMobileBrand ? 22 : 36),
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
            const SizedBox(height: 8),
            Text(
              'Access audit plans, reviews, action items, and reports.',
              style: AppTextStyles.body13,
            ),
            const SizedBox(height: 24),
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
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.medium13.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onSubmit,
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                        : const Icon(Icons.login, size: 18),
                label: Text(
                  isLoading ? 'Signing in' : 'Sign in securely',
                  style: AppTextStyles.medium14.copyWith(
                    color: AppColors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final resp = await dio.get('/test-smtp');
      final data = resp.data is Map ? resp.data as Map : <String, dynamic>{};
      final ok = data['data']?['ok'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Test email sent to Flutter.developer@vistarlogitek.com'
            : 'SMTP failed: ${data['data']?['error'] ?? 'unknown error'}'),
        backgroundColor: ok ? AppColors.secondary : AppColors.danger,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request failed: $e'),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _sendTest,
      icon: _loading
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
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      padding: const EdgeInsets.all(36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CompactBrandHeader(onDark: true),
          const Spacer(),
          Text(
            'Audit control that stays clear under pressure.',
            style: AppTextStyles.headline22.copyWith(
              color: AppColors.white,
              fontSize: 30,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Plan audits, capture findings, track action plans, and keep every stakeholder aligned from one workspace.',
            style: AppTextStyles.body14.copyWith(
              color: AppColors.white.withValues(alpha: 0.84),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 30),
          const _AuditPreview(),
          const Spacer(),
          const Row(
            children: [
              _MetricPill(
                icon: Icons.verified_outlined,
                label: 'Live status',
                color: AppColors.secondary,
              ),
              SizedBox(width: 10),
              _MetricPill(
                icon: Icons.schedule_outlined,
                label: 'Due tracking',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.white : AppColors.textPrimary;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: onDark
                ? Border.all(color: AppColors.white.withValues(alpha: 0.30))
                : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: onDark ? 0.0 : 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vistar Audit',
              style: AppTextStyles.title18.copyWith(color: foreground),
            ),
            Text(
              'Management console',
              style: AppTextStyles.body12.copyWith(
                color:
                    onDark
                        ? AppColors.white.withValues(alpha: 0.72)
                        : AppColors.textSecondary,
              ),
            ),
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
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
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
            color: AppColors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.medium13.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.body12.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                ),
              ),
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
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.medium12.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F1FC), AppColors.white, Color(0xFFEAF3DE)],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.045)
          ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
