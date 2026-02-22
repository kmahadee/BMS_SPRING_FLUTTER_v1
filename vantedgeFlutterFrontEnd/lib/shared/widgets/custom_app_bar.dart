import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLeading;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showNotifications;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final bool automaticallyImplyLeading;
  final double toolbarHeight;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showLeading = true,
    this.leading,
    this.actions,
    this.showNotifications = true,
    this.notificationCount,
    this.onNotificationTap,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.flexibleSpace,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build actions list with notification bell if needed
    final List<Widget> appBarActions = [
      if (actions != null) ...actions!,
      if (showNotifications)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildNotificationButton(context, colorScheme),
        ),
    ];

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      leading: showLeading ? leading : null,
      automaticallyImplyLeading: automaticallyImplyLeading && showLeading,
      actions: appBarActions.isEmpty ? null : appBarActions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _getStatusBarIconBrightness(
          backgroundColor ?? colorScheme.primary,
        ),
        statusBarBrightness: _getStatusBarBrightness(
          backgroundColor ?? colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, ColorScheme colorScheme) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: foregroundColor ?? colorScheme.onPrimary,
          ),
          if (notificationCount != null && notificationCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: backgroundColor ?? colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    notificationCount! > 99 ? '99+' : '$notificationCount',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: onNotificationTap ?? () {
        // Default navigation to notifications screen
        Navigator.pushNamed(context, '/notifications');
      },
      tooltip: 'Notifications',
    );
  }

  Brightness _getStatusBarIconBrightness(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark icons
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
        ? Brightness.dark
        : Brightness.light;
  }

  Brightness _getStatusBarBrightness(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor);
  }

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

// Custom AppBar with search functionality
class SearchableAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final Function(String) onSearchChanged;
  final VoidCallback? onSearchClose;
  final List<Widget>? actions;
  final bool showNotifications;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;

  const SearchableAppBar({
    super.key,
    required this.title,
    required this.searchHint,
    required this.onSearchChanged,
    this.onSearchClose,
    this.actions,
    this.showNotifications = true,
    this.notificationCount,
    this.onNotificationTap,
  });

  @override
  State<SearchableAppBar> createState() => _SearchableAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchableAppBarState extends State<SearchableAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        widget.onSearchChanged('');
        widget.onSearchClose?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.7),
                ),
              ),
              style: TextStyle(color: colorScheme.onPrimary),
              onChanged: widget.onSearchChanged,
            )
          : Text(widget.title),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
        if (!_isSearching && widget.actions != null) ...widget.actions!,
        if (!_isSearching && widget.showNotifications)
          _buildNotificationButton(context, colorScheme),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: colorScheme.onPrimary,
            ),
            if (widget.notificationCount != null && widget.notificationCount! > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      widget.notificationCount! > 99
                          ? '99+'
                          : '${widget.notificationCount}',
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: widget.onNotificationTap ?? () {
          Navigator.pushNamed(context, '/notifications');
        },
        tooltip: 'Notifications',
      ),
    );
  }
}

// Collapsing AppBar with flexible space
class CollapsingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? background;
  final List<Widget>? actions;
  final bool showNotifications;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;
  final double expandedHeight;
  final bool pinned;
  final bool floating;

  const CollapsingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.background,
    this.actions,
    this.showNotifications = true,
    this.notificationCount,
    this.onNotificationTap,
    this.expandedHeight = 200.0,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      actions: [
        if (actions != null) ...actions!,
        if (showNotifications)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildNotificationButton(context, colorScheme),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title),
        centerTitle: true,
        background: background ??
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, ColorScheme colorScheme) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: colorScheme.onPrimary,
          ),
          if (notificationCount != null && notificationCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    notificationCount! > 99 ? '99+' : '$notificationCount',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: onNotificationTap ?? () {
        Navigator.pushNamed(context, '/notifications');
      },
      tooltip: 'Notifications',
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(expandedHeight);
}