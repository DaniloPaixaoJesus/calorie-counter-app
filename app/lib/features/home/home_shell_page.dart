import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/features/sync/presentation/sync_status_widget.dart';
import 'package:calorie_counter_app/features/sync/presentation/sync_view_model.dart';

import 'add_meal_entry_page.dart';
import 'home_page.dart';
import 'view_model.dart';

class HomeShellPage extends StatefulWidget {
  final bool? showAds;

  const HomeShellPage({super.key, this.showAds});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<HomeViewModel>().refreshCurrentDate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _selectDestination(int index) {
    context.read<HomeViewModel>().refreshCurrentDate();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = context.watch<SubscriptionService?>();
    final syncViewModel = context.watch<SyncViewModel?>();
    final showAds =
        widget.showAds ?? subscriptionService?.shouldShowAds ?? true;
    final pages = [
      HomePage(showAds: showAds),
      AddMealEntryPage(
        showAds: showAds,
        onMealSaved: () => setState(() => _currentIndex = 0),
      ),
    ];
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          if (syncViewModel != null) SyncStatusWidget(viewModel: syncViewModel),
          Expanded(child: IndexedStack(index: _currentIndex, children: pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline_rounded),
            selectedIcon: const Icon(Icons.add_circle_rounded),
            label: l10n.add,
          ),
        ],
      ),
    );
  }
}
