import 'package:Maya/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';



class TabLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const TabLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends State<TabLayout> {
  static const _tabs = [
    {
      'route': '/home',
      'asset': 'assets/home.png',
      'label': 'Home',
    },
    {
      'route': '/tasks',
      'asset': 'assets/task.png',
      'label': 'Tasks',
    },
    {
      'route': '/maya',
      'asset': 'assets/star.png',
      'label': 'AI',
    },
    {
      'route': '/settings',
      'asset': 'assets/setup.png',
      'label': 'Setup',
    },
    {
      'route': '/other',
      'asset': 'assets/other.png',
      'label': 'Others',
    },
  ];

  // ── Persistent tab back-stack (exactly the same logic you had) ──
  static final List<int> _tabHistory = [0];
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    if (!_tabHistory.contains(widget.currentIndex)) {
      _tabHistory.add(widget.currentIndex);
    }
  }

  @override
  void didUpdateWidget(covariant TabLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _tabHistory.last) {
      _tabHistory.remove(widget.currentIndex);
      _tabHistory.add(widget.currentIndex);
    }
  }

  // ── Back handling (unchanged) ──
  Future<bool> _handleBack(BuildContext context) async {
    final router = GoRouter.of(context);
    final uri = router.routeInformationProvider.value.uri.toString();

    // 1. Inner route → pop
    if (_isInnerRoute(uri)) {
      router.pop();
      return false;
    }

    // 2. Previous tab in history
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

    // 3. Exit dialog
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

  bool _isInnerRoute(String uri) {
    for (final tab in _tabs) {
      if (uri == tab['route']) return false;
    }
    return true;
  }

  // ── New curved navigation bar UI (exactly the look you asked for) ──
  Widget _buildCurvedNavBar(int currentIndex) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 75,
      color: AppColors.whiteClr,
      buttonBackgroundColor: Colors.transparent,
backgroundColor: AppColors.bgColor,
      animationDuration: const Duration(milliseconds: 300),
      items: List.generate(_tabs.length, (i) {
        final bool isSelected = currentIndex == i;
        final String asset = _tabs[i]['asset'] as String;
        final String label = _tabs[i]['label'] as String;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: isSelected ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: isSelected
                  ? const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Image.asset(
                asset,
                height: 26,
                color: isSelected
                    ? Colors.white
                    : AppColors.balckClr.withOpacity(0.6),
                errorBuilder: (_, __, ___) => Icon(
                  _fallbackIcon(i),
                  size: 26,
                  color: isSelected ? Colors.white : AppColors.balckClr.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSelected ? label : '',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
      onTap: (index) {
        if (index != currentIndex) {
          context.go(_tabs[index]['route'] as String);
        }
      },
    );
  }

  // Fallback icons if the PNGs are missing
  IconData _fallbackIcon(int index) => [
        FeatherIcons.home,
        FeatherIcons.checkSquare,
        FeatherIcons.star,
        FeatherIcons.settings,
        FeatherIcons.moreHorizontal,
      ][index];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleBack(context),
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        extendBody: true, // required for the curve to float over the body
        body: widget.child,
        bottomNavigationBar: _buildCurvedNavBar(widget.currentIndex),
      ),
    );
  }
}