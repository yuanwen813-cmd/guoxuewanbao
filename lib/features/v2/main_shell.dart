import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';

class GuoxueMainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const GuoxueMainShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        height: 68,
        backgroundColor: GuoXueColors.ricePaper,
        indicatorColor: GuoXueColors.gold.withOpacity(0.24),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => context.go(_destinations[index].path),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    final index = _destinations.indexWhere((destination) {
      if (destination.path == '/') {
        return location == '/';
      }
      return location == destination.path ||
          location.startsWith('${destination.path}/');
    });
    return index < 0 ? 0 : index;
  }
}

class _MainDestination {
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  const _MainDestination({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });
}

const _destinations = [
  _MainDestination(
    label: '首页',
    path: '/',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  _MainDestination(
    label: '问事',
    path: '/ask',
    icon: Icons.question_answer_outlined,
    selectedIcon: Icons.question_answer,
  ),
  _MainDestination(
    label: '命盘',
    path: '/natal',
    icon: Icons.account_circle_outlined,
    selectedIcon: Icons.account_circle,
  ),
  _MainDestination(
    label: '我的',
    path: '/mine',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];
