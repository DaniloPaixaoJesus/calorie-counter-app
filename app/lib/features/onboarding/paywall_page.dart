import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/home_shell_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  _PremiumPlan _selectedPlan = _PremiumPlan.monthly;

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      adaptivePageRoute(
        context: context,
        builder: (_) => const _PremiumGoogleLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.premiumPlans),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xs,
                horizontalPadding,
                AppSpacing.lg,
              ),
              children: [
                Text(
                  l10n.chooseIdealPlan,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _PremiumPlanCard(
                  title: l10n.monthly,
                  price: 'R\$ 14,90',
                  period: l10n.perMonth,
                  badge: l10n.mostChosen,
                  selected: _selectedPlan == _PremiumPlan.monthly,
                  onTap: () {
                    setState(() => _selectedPlan = _PremiumPlan.monthly);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _PremiumPlanCard(
                  title: l10n.yearly,
                  price: 'R\$ 119,90',
                  period: l10n.perYear,
                  badge: l10n.save33,
                  selected: _selectedPlan == _PremiumPlan.yearly,
                  onTap: () {
                    setState(() => _selectedPlan = _PremiumPlan.yearly);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => _openLogin(context),
                  child: Text(l10n.continueLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PremiumPlan { monthly, yearly }

class _PremiumPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String badge;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumPlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.65)
        : const Color(0xFFD8B15A).withValues(alpha: 0.55);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE78A),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8A6A00),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    period,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final bullet
                in AppLocalizations.of(context).premiumPlanBullets)
              _PlanBullet(bullet),
          ],
        ),
      ),
    );
  }
}

class _PremiumGoogleLoginPage extends StatefulWidget {
  const _PremiumGoogleLoginPage();

  @override
  State<_PremiumGoogleLoginPage> createState() =>
      _PremiumGoogleLoginPageState();
}

class _PremiumGoogleLoginPageState extends State<_PremiumGoogleLoginPage> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoadingGoogleLogin = false;
  String? _googleLoginError;

  Future<void> _continueWithGoogle(BuildContext context) async {
    if (_isLoadingGoogleLogin) return;
    final googleLoginCancelled =
        AppLocalizations.of(context).googleLoginCancelled;

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
      setState(() => _googleLoginError = googleLoginCancelled);
    } on GoogleAuthException catch (error) {
      if (!mounted) return;
      setState(() => _googleLoginError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoogleLogin = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xxl,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    l10n.accessYourAccount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.premiumLoginSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoadingGoogleLogin
                        ? null
                        : () => _continueWithGoogle(context),
                    icon: const _GoogleBrandIcon(),
                    label: Text(
                      _isLoadingGoogleLogin
                          ? l10n.connectingGoogle
                          : l10n.continueWithGoogle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
                    ),
                  const Spacer(),
                  Text(
                    l10n.secureCloudData,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanBullet extends StatelessWidget {
  final String text;

  const _PlanBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '- ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleBrandIcon extends StatelessWidget {
  const _GoogleBrandIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
