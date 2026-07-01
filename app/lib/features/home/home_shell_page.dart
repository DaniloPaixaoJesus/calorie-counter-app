import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';

import 'add_meal_entry_page.dart';
import 'home_page.dart';

class HomeShellPage extends StatefulWidget {
  final bool? showAds;

  const HomeShellPage({super.key, this.showAds});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = context.watch<SubscriptionService?>();
    final showAds =
        widget.showAds ?? subscriptionService?.shouldShowAds ?? true;
    final pages = [
      HomePage(showAds: showAds),
      AddMealEntryPage(
        showAds: showAds,
        onMealSaved: () => setState(() => _currentIndex = 0),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Adicionar',
          ),
        ],
      ),
    );
  }
}
