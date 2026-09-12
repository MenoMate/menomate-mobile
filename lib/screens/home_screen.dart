import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/theme_atmosphere.dart';
import 'tabs/home_tab.dart';
import 'tabs/assistant_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';

class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(HomeTabIndexNotifier.new);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  final List<Widget> _tabs = const [
    HomeTab(),
    AssistantTab(),
    HistoryTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: ThemeAtmosphereBackground(
        child: IndexedStack(
          index: currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeTabIndexProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.secondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: 'Care',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
