import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/app_provider.dart';
import '../../data/providers/chatbot_provider.dart';
import '../../data/services/notification_service.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'warnings/warnings_screen.dart';
import 'chatbot/chatbot_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    MapScreen(),
    WarningsScreen(),
    ChatbotScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize app data and chatbot greeting after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appProvider = context.read<AppProvider>();
      final chatProvider = context.read<ChatbotProvider>();
      await appProvider.initialize();
      if (appProvider.geminiApiKey.isNotEmpty) {
        chatProvider.initializeGemini(appProvider.geminiApiKey);
      }
      // Request notification permissions after a short delay so splash is gone
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) await NotificationService().requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final activeCount = provider.activeWarnings.length;
          return Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map_rounded),
                  activeIcon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text('$activeCount'),
                    backgroundColor: AppColors.danger,
                    child: const Icon(Icons.warning_amber_rounded),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text('$activeCount'),
                    backgroundColor: AppColors.danger,
                    child: const Icon(Icons.warning_amber_rounded),
                  ),
                  label: 'Warnings',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.smart_toy_rounded),
                  activeIcon: Icon(Icons.smart_toy_rounded),
                  label: 'AquaAI',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
