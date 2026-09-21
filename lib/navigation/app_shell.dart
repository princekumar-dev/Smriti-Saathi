import 'package:flutter/material.dart';

import '../screens/activities_screen.dart';
import '../screens/family_screen.dart';
import '../screens/home_screen.dart';
import '../screens/memories_screen.dart';
import '../screens/saathi_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SaathiScreen(),
    MemoriesScreen(),
    ActivitiesScreen(),
    FamilyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'global-saathi-action',
        onPressed: () {
          setState(() => _selectedIndex = 1);
        },
        backgroundColor: AppTheme.warmAmber,
        foregroundColor: AppTheme.deepForest,
        elevation: 6,
        icon: const Icon(Icons.auto_awesome_rounded, size: 23),
        label: const Text('Ask Saathi'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _LuxuryElderlyNavBar(
        selectedIndex: _selectedIndex,
        onSelect: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _LuxuryElderlyNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _LuxuryElderlyNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper,
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepForest.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppTheme.divider, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.mic_none_rounded, Icons.mic_rounded, 'Voice Saathi'),
              _navItem(2, Icons.photo_album_outlined, Icons.photo_album_rounded, 'Memories'),
              _navItem(3, Icons.extension_outlined, Icons.extension_rounded, 'Activities'),
              _navItem(4, Icons.people_outline_rounded, Icons.people_rounded, 'Family'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = selectedIndex == index;

    return Expanded(
      child: AnimatedScaleButton(
        onTap: () => onSelect(index),
        scaleDown: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppTheme.sage : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.14 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 26,
                  color: selected ? AppTheme.forest : AppTheme.muted,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: selected ? AppTheme.deepForest : AppTheme.muted,
                    letterSpacing: selected ? 0.2 : 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openSettings(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}
