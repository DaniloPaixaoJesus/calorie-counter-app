import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/home_shell_page.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoadingGoogleLogin = false;
  String? _googleLoginError;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _continueWithGoogle(BuildContext context) async {
    if (_isLoadingGoogleLogin) return;

    setState(() {
      _isLoadingGoogleLogin = true;
      _googleLoginError = null;
    });

    try {
      final account = await _googleAuthService.signIn();
      if (!context.mounted) return;

      await context.read<SubscriptionService>().activatePremium(
            userName: account.displayName,
            userEmail: account.email,
            userPhotoUrl: account.photoUrl,
          );
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShellPage()),
        (_) => false,
      );
    } on GoogleAuthCancelledException {
      if (!mounted) return;
      setState(() {
        _googleLoginError = 'Login Google cancelado.';
      });
    } on GoogleAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _googleLoginError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogleLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                Text(
                  'Entre para continuar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'O Premium libera estimativas ilimitadas, sincronização e recursos avançados.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BenefitRow(
                          icon: Icons.auto_awesome_rounded,
                          text: 'Estimativas ilimitadas',
                        ),
                        _BenefitRow(
                          icon: Icons.pie_chart_rounded,
                          text: 'Macronutrientes',
                        ),
                        _BenefitRow(
                          icon: Icons.cloud_done_rounded,
                          text: 'Backup em nuvem',
                        ),
                        _BenefitRow(
                          icon: Icons.block_rounded,
                          text: 'Sem anúncios',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Você autenticará sua própria conta para ativar o Premium.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_isAndroid)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFDADCE0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoadingGoogleLogin
                          ? null
                          : () => _continueWithGoogle(context),
                      icon: const _GoogleMark(),
                      label: Text(
                        _isLoadingGoogleLogin
                            ? 'Conectando ao Google...'
                            : 'Continuar com Google',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (_isIos)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.apple_rounded),
                      label: const Text('Continuar com Apple'),
                    ),
                  ),
                if (!_isAndroid && !_isIos)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.devices_rounded),
                      label: const Text('Login indisponível nesta plataforma'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (_googleLoginError != null)
                  Text(
                    _googleLoginError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                  )
                else
                  Text(
                    _isIos
                        ? 'Use sua conta Apple para liberar o Premium no iOS.'
                        : 'Use sua conta Google para liberar o Premium no Android.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
