import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes/app_router.dart';

/// Production-grade custom app bar with intelligent back navigation
class MayaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool automaticImplyLeading;

  const MayaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isMainTab = AppRouter.isMainTab(currentLocation);
    final shouldShowBack = showBackButton && 
                          !isMainTab && 
                          automaticImplyLeading && 
                          AppRouter.navigationHistory.canGoBack();

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor ?? const Color(0xFF1E293B),
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: shouldShowBack
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: foregroundColor ?? Colors.white,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => _handleBack(context),
              tooltip: 'Back',
            )
          : null,
      actions: actions,
    );
  }

  void _handleBack(BuildContext context) async {
    final didGoBack = await AppRouter.goBack(context);
    if (!didGoBack) {
      // Fallback: try Navigator.pop if goBack failed
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Reusable back button widget
class MayaBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const MayaBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: color ?? Colors.white,
        size: size,
      ),
      onPressed: onPressed ?? () async {
        final didGoBack = await AppRouter.goBack(context);
        if (!didGoBack && context.mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      tooltip: tooltip ?? 'Back',
    );
  }
}

/// Navigation helper mixin for StatefulWidget pages
mixin NavigationHelper<T extends StatefulWidget> on State<T> {
  /// Navigate to a route
  void navigateTo(String route) {
    AppRouter.navigateTo(context, route);
  }

  /// Navigate back
  Future<void> navigateBack() async {
    await AppRouter.goBack(context);
  }

  /// Replace current route
  void replaceTo(String route) {
    AppRouter.replaceTo(context, route);
  }

  /// Clear history and navigate
  void clearAndNavigateTo(String route) {
    AppRouter.clearAndNavigateTo(context, route);
  }

  /// Push a new route
  void pushRoute(String route) {
    AppRouter.push(context, route);
  }

  /// Check if can go back
  bool canGoBack() {
    return AppRouter.navigationHistory.canGoBack();
  }

  /// Get current location
  String getCurrentLocation() {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (e) {
      debugPrint('⚠️ NavigationHelper: Error getting location: $e');
      return '/';
    }
  }

  /// Check if on main tab
  bool isOnMainTab() {
    return AppRouter.isMainTab(getCurrentLocation());
  }

  /// Get navigation history
  List<String> getNavigationHistory() {
    return AppRouter.navigationHistory.fullHistory;
  }
}

/// Navigation extension for BuildContext
extension NavigationExtension on BuildContext {
  /// Navigate to a route using AppRouter
  void navigateTo(String route) {
    AppRouter.navigateTo(this, route);
  }

  /// Go back using AppRouter
  Future<void> navigateBack() async {
    await AppRouter.goBack(this);
  }

  /// Replace current route
  void replaceTo(String route) {
    AppRouter.replaceTo(this, route);
  }

  /// Clear and navigate
  void clearAndNavigateTo(String route) {
    AppRouter.clearAndNavigateTo(this, route);
  }

  /// Push a new route
  void pushRoute(String route) {
    AppRouter.push(this, route);
  }

  /// Get current location
  String get currentLocation {
    try {
      return GoRouterState.of(this).uri.path;
    } catch (e) {
      debugPrint('⚠️ NavigationExtension: Error getting location: $e');
      return '/';
    }
  }

  /// Check if on main tab
  bool get isOnMainTab => AppRouter.isMainTab(currentLocation);

  /// Get navigation history
  List<String> get navigationHistory => AppRouter.navigationHistory.fullHistory;

  /// Check if can go back
  bool get canGoBack => AppRouter.navigationHistory.canGoBack();
}

/// Wrapper widget that handles back navigation for its child
class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final bool handleBackButton;
  final VoidCallback? onBackPressed;

  const NavigationWrapper({
    super.key,
    required this.child,
    this.handleBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!handleBackButton) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          final didGoBack = await AppRouter.goBack(context);
          if (!didGoBack && context.mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: child,
    );
  }
}

/// Debug widget to show navigation history (for development)
class NavigationDebugInfo extends StatelessWidget {
  const NavigationDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigation Debug',
            style: TextStyle(
              color: Colors.yellow[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${context.currentLocation}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'History: ${AppRouter.navigationHistory.fullHistory.join(' → ')}',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Can go back: ${AppRouter.navigationHistory.canGoBack()}',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
          ),
          Text(
            'History count: ${AppRouter.navigationHistory.count}',
            style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// SafeNavigationBuilder - Ensures navigation happens after build
class SafeNavigationBuilder extends StatefulWidget {
  final Widget child;
  final String? initialRoute;

  const SafeNavigationBuilder({
    super.key,
    required this.child,
    this.initialRoute,
  });

  @override
  State<SafeNavigationBuilder> createState() => _SafeNavigationBuilderState();
}

class _SafeNavigationBuilderState extends State<SafeNavigationBuilder> {
  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppRouter.navigationHistory.push(widget.initialRoute!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}