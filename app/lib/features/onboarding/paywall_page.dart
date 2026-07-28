import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_elevation.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/design_system/premium_crown_icon.dart';
import 'package:calorie_counter_app/features/home/home_shell_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/bff/user_bff_service.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaywallPage extends StatefulWidget {
  final GoogleAuthService? restoreGoogleAuthService;
  final bool restorePurchaseOnOpen;
  final bool returnToPlanSelectionOnNotFound;

  const PaywallPage({
    super.key,
    this.restoreGoogleAuthService,
    this.restorePurchaseOnOpen = false,
    this.returnToPlanSelectionOnNotFound = false,
  });

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  _PremiumPlan _selectedPlan = _PremiumPlan.monthly;
  late final GoogleAuthService _restoreGoogleAuthService;
  bool _isRestoringPurchase = false;
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    _restoreGoogleAuthService =
        widget.restoreGoogleAuthService ?? GoogleAuthService();
    if (widget.restorePurchaseOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restorePurchase());
    }
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      adaptivePageRoute(
        context: context,
        builder: (_) => const _PremiumGoogleLoginPage(),
      ),
    );
  }

  Future<void> _restorePurchase() async {
    if (_isRestoringPurchase) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isRestoringPurchase = true;
      _restoreError = null;
    });

    try {
      final account = await _restoreGoogleAuthService.signIn();
      if (!mounted) return;
      final restored = await context
          .read<SubscriptionService>()
          .restorePremiumWithGoogle(account);
      if (!mounted) return;
      if (!restored) {
        await _restoreGoogleAuthService.signOut();
        if (!mounted) return;
        if (widget.returnToPlanSelectionOnNotFound) {
          Navigator.of(context).pop(PaywallResult.noActivePlan(account.email));
        } else {
          setState(() {
            _restoreError = l10n.noActivePremiumPlanForEmail(account.email);
          });
        }
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShellPage()),
        (_) => false,
      );
    } on GoogleAuthCancelledException {
      if (mounted) setState(() => _restoreError = l10n.googleLoginCancelled);
    } on GoogleAuthException catch (error) {
      if (mounted) setState(() => _restoreError = error.message);
    } on UserBffException catch (error) {
      if (mounted) setState(() => _restoreError = error.message);
    } catch (_) {
      if (mounted) setState(() => _restoreError = l10n.googleLoginFailed);
    } finally {
      if (mounted) setState(() => _isRestoringPurchase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
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
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xs,
                horizontalPadding,
                AppSpacing.lg,
              ),
              children: [
                Container(
                  key: const ValueKey('premium-paywall-hero'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF3D8),
                        colorScheme.primaryContainer.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: const Color(0xFFB56A00).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const PremiumCrownIcon(size: 30),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.premiumPlans,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: const Color(0xFF8A5600),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.chooseIdealPlan,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PremiumPlanCard(
                  key: const ValueKey('monthly-plan-card'),
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
                  key: const ValueKey('yearly-plan-card'),
                  title: l10n.yearly,
                  price: 'R\$ 119,90',
                  period: l10n.perYear,
                  badge: l10n.save33,
                  selected: _selectedPlan == _PremiumPlan.yearly,
                  onTap: () {
                    setState(() => _selectedPlan = _PremiumPlan.yearly);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  key: const ValueKey('premium-benefits-panel'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final bullet in l10n.premiumPlanBullets)
                        _PlanBullet(bullet),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed:
                      _isRestoringPurchase ? null : () => _openLogin(context),
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(l10n.continueLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isRestoringPurchase ? null : _restorePurchase,
                  icon: _isRestoringPurchase
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_rounded),
                  label: Text(
                    _isRestoringPurchase
                        ? l10n.restoringPurchase
                        : l10n.restorePurchase,
                  ),
                ),
                if (_restoreError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    key: const ValueKey('restore-purchase-error'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _restoreError!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PremiumPlan { monthly, yearly }

class PaywallResult {
  final String email;

  const PaywallResult.noActivePlan(this.email);
}

class _PremiumPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String badge;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumPlanCard({
    super.key,
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
    const premiumColor = Color(0xFFB56A00);
    final borderColor = selected
        ? premiumColor.withValues(alpha: 0.78)
        : colorScheme.outlineVariant.withValues(alpha: 0.75);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      side: BorderSide(
        color: borderColor,
        width: selected ? 1.8 : 1,
      ),
    );

    return Material(
      color: Colors.transparent,
      elevation: selected ? AppElevation.level2 : AppElevation.level1,
      shadowColor: premiumColor.withValues(alpha: 0.2),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? null : colorScheme.surface,
            gradient: selected
                ? LinearGradient(
                    colors: [
                      colorScheme.surface,
                      const Color(0xFFFFF3D8).withValues(alpha: 0.76),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? premiumColor : colorScheme.outline,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: selected
                                      ? premiumColor
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE78A),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            badge,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF8A6A00),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          price,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            period,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final googleLoginFailed = AppLocalizations.of(context).googleLoginFailed;

    setState(() {
      _isLoadingGoogleLogin = true;
      _googleLoginError = null;
    });

    try {
      final account = await _googleAuthService.signIn();
      if (!context.mounted) return;

      await context.read<SubscriptionService>().authenticatePremiumWithGoogle(
            account,
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
    } on UserBffException catch (error) {
      if (!mounted) return;
      setState(() => _googleLoginError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _googleLoginError = googleLoginFailed);
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
          Icon(
            Icons.check_circle_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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
