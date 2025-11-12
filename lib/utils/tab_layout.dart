import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';

class TabLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const TabLayout({super.key, required this.child, required this.currentIndex});

  @override
  State<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends State<TabLayout> {
  static const _tabs = [
    {'route': '/home', 'icon': FeatherIcons.home, 'label': 'Home'},
    {'route': '/tasks', 'icon': FeatherIcons.checkSquare, 'label': 'Tasks'},
    {'route': '/maya', 'icon': FeatherIcons.star, 'label': 'Maya'},
    {'route': '/settings', 'icon': FeatherIcons.settings, 'label': 'Settings'},
    {'route': '/other', 'icon': FeatherIcons.moreHorizontal, 'label': 'Other'},
  ];

  /// Persistent tab backstack across navigations
  static final List<int> _tabHistory = [0];

  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Ensure the initial tab is tracked
    if (!_tabHistory.contains(widget.currentIndex)) {
      _tabHistory.add(widget.currentIndex);
    }
  }

  @override
  void didUpdateWidget(covariant TabLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep track of tab switches
    if (widget.currentIndex != _tabHistory.last) {
      _tabHistory.remove(widget.currentIndex);
      _tabHistory.add(widget.currentIndex);
    }
  }

  Future<bool> _handleBack(BuildContext context) async {
    final router = GoRouter.of(context);
    final uri = router.routeInformationProvider.value.uri.toString();

    // 1️⃣ Handle in-tab back (inner route)
    if (_isInnerRoute(uri)) {
      router.pop();
      return false;
    }

    // 2️⃣ Go to previous tab if history exists
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousIndex = _tabHistory.last;
      final prevRoute = _tabs[previousIndex]['route'] as String;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (router.routeInformationProvider.value.uri.toString() != prevRoute) {
          context.go(prevRoute);
        }
      });
      return false;
    }

    // 3️⃣ Exit prompt
    if (_isDialogShowing) return false;
    _isDialogShowing = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Exit App?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Do you really want to close the app?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Exit', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    _isDialogShowing = false;
    return shouldExit ?? false;
  }

  /// Returns true if the route is a subpage (like `/tasks/:id`).
  bool _isInnerRoute(String uri) {
    for (final tab in _tabs) {
      final route = tab['route']!;
      if (uri == route) return false;
    }
    // If not a tab root, treat as an inner route
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleBack(context),
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        extendBody: true,
        body: widget.child,
        bottomNavigationBar: _buildBottomNavigationBar(context, widget.currentIndex),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    const activeColor = Color(0xFF60A5FA);
    const inactiveColor = Color(0xFF9CA3AF);
    const backgroundColor = Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.all(16),
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final tab = _tabs[index];
                  final isActive = currentIndex == index;
                  final isCentral = index == 2;

                  if (isCentral) return const Expanded(child: SizedBox());

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (!isActive) context.go(tab['route'] as String);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab['icon'] as IconData,
                                size: 22,
                                color: isActive ? activeColor : inactiveColor),
                            const SizedBox(height: 4),
                            Text(
                              tab['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isActive ? activeColor : inactiveColor,
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 32,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                if (widget.currentIndex != 2) context.go('/maya');
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/maya_logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      FeatherIcons.star,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
