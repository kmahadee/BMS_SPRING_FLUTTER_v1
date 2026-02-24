import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'bottom_nav_bar.dart';
import 'custom_app_bar.dart';

/// Main scaffold wrapper that provides consistent navigation structure
class MainScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String? title;
  final bool showAppBar;
  final bool showDrawer;
  final bool showBottomNav;
  final List<Widget>? appBarActions;
  final bool showNotifications;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? customAppBar;
  final Widget? bottomSheet;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
    this.title,
    this.showAppBar = true,
    this.showDrawer = true,
    this.showBottomNav = true,
    this.appBarActions,
    this.showNotifications = true,
    this.notificationCount,
    this.onNotificationTap,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.customAppBar,
    this.bottomSheet,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _handleNavigation(String route) {
    if (route != widget.currentRoute) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? (widget.customAppBar ??
              CustomAppBar(
                title: widget.title ?? _getDefaultTitle(widget.currentRoute),
                actions: widget.appBarActions,
                showNotifications: widget.showNotifications,
                notificationCount: widget.notificationCount,
                onNotificationTap: widget.onNotificationTap,
              ))
          : null,
      drawer: widget.showDrawer ? const AppDrawer() : null,
      body: widget.child,
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentRoute: widget.currentRoute,
              onItemTapped: _handleNavigation,
            )
          : null,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomSheet: widget.bottomSheet,
    );
  }

  String _getDefaultTitle(String route) {
    // Get display name from AppRoutes or return a default
    return route.split('/').last.replaceAll('-', ' ').toUpperCase();
  }
}

/// Simplified scaffold for screens that don't need full navigation
class SimpleScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final PreferredSizeWidget? appBar;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomSheet;
  final Color? backgroundColor;

  const SimpleScaffold({
    super.key,
    required this.child,
    this.title,
    this.appBar,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomSheet,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          (title != null
              ? CustomAppBar(
                  title: title!,
                  showLeading: showBackButton,
                  actions: actions,
                  showNotifications: false,
                )
              : null),
      body: child,
      floatingActionButton: floatingActionButton,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
    );
  }
}

/// Tabbed scaffold with tab bar
class TabbedScaffold extends StatelessWidget {
  final String title;
  final List<Tab> tabs;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool showNotifications;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;

  const TabbedScaffold({
    super.key,
    required this.title,
    required this.tabs,
    required this.children,
    this.actions,
    this.showNotifications = true,
    this.notificationCount,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: CustomAppBar(
          title: title,
          actions: actions,
          showNotifications: showNotifications,
          notificationCount: notificationCount,
          onNotificationTap: onNotificationTap,
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(children: children),
      ),
    );
  }
}

/// Scrollable scaffold with collapsing app bar
class ScrollableScaffold extends StatelessWidget {
  final String title;
  final Widget? headerWidget;
  final List<Widget> slivers;
  final bool showDrawer;
  final bool showBottomNav;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ScrollableScaffold({
    super.key,
    required this.title,
    this.headerWidget,
    required this.slivers,
    this.showDrawer = true,
    this.showBottomNav = true,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: showDrawer ? const AppDrawer() : null,
      body: CustomScrollView(
        slivers: [
          CollapsingAppBar(
            title: title,
            actions: actions,
            background: headerWidget,
          ),
          ...slivers,
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentRoute: currentRoute,
              onItemTapped: (route) {
                Navigator.pushReplacementNamed(context, route);
              },
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Helper to determine which scaffold type to use
class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String? title;
  final ScaffoldType type;
  final Map<String, dynamic>? config;

  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
    this.title,
    this.type = ScaffoldType.main,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ScaffoldType.main:
        return MainScaffold(
          currentRoute: currentRoute,
          title: title,
          child: child,
        );
      case ScaffoldType.simple:
        return SimpleScaffold(
          title: title,
          child: child,
        );
      case ScaffoldType.tabbed:
        return TabbedScaffold(
          title: title ?? 'Tabs',
          tabs: config?['tabs'] ?? [],
          children: config?['children'] ?? [child],
        );
      case ScaffoldType.scrollable:
        return ScrollableScaffold(
          title: title ?? 'Page',
          currentRoute: currentRoute,
          slivers: config?['slivers'] ?? [
            SliverToBoxAdapter(child: child),
          ],
        );
    }
  }
}

enum ScaffoldType {
  main,
  simple,
  tabbed,
  scrollable,
}