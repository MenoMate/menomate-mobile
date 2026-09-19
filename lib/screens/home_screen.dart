import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../widgets/theme_atmosphere.dart';
import '../screens/calendar_screen.dart';
import '../screens/log_hub_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/assistant_tab.dart';
import 'tabs/insights_tab.dart';
import 'tabs/settings_tab.dart';

class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(
  HomeTabIndexNotifier.new,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Primary destinations: Home | Calendar | Log | Insights | Care | More.
  // Calendar is the Year→Month→Day hierarchy; Log is the dedicated
  // logging hub; More hosts Settings/Profile/Health. History remains as
  // a legacy pushed route (/history) aliasing the calendar.
  final List<Widget> _tabs = const [
    HomeTab(),
    CalendarScreen(),
    LogHubScreen(),
    InsightsTab(),
    AssistantTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: ThemeAtmosphereBackground(
        child: IndexedStack(index: currentIndex, children: _tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeTabIndexProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        // Selection is interaction indigo, not menstrual rose: rose keeps
        // its period-only meaning instead of marking navigation.
        selectedItemColor: MenoMateTheme.interactionColor(
          theme.brightness == Brightness.dark,
        ),
        unselectedItemColor: colorScheme.secondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: 'Care',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
