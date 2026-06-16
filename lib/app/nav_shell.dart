import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Today', icon: Icons.fitness_center, path: '/today'),
    _TabItem(label: 'History', icon: Icons.history, path: '/history'),
    _TabItem(label: 'Setup', icon: Icons.tune, path: '/setup'),
    _TabItem(label: 'Settings', icon: Icons.settings, path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final String path;
}
