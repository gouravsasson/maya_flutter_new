import 'package:Maya/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class TabLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const TabLayout({super.key, required this.child, required this.currentIndex});

  @override
  State<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends State<TabLayout> {
  static const _tabs = [
    {'route': '/home', 'asset': 'assets/home.png', 'label': 'Home'},
    {'route': '/tasks', 'asset': 'assets/task.png', 'label': 'Tasks'},
    {'route': '/maya', 'asset': 'assets/star.png', 'label': 'AI'},
    {'route': '/settings', 'asset': 'assets/setup.png', 'label': 'Setup'},
    {'route': '/other', 'asset': 'assets/other.png', 'label': 'Others'},
  ];

  final bool _isDialogShowing = false;
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        extendBody: true,
        body: widget.child,
        bottomNavigationBar: _buildCurvedNavBar(widget.currentIndex),
      ),
    );
  }

  Future<void> _handleBackButton() async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    if (widget.currentIndex != 0) {
      context.go('/home');
      return;
    }

    // 3. On home - double tap to exit
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Do you want to exit this app?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Cancel
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  SystemNavigator.pop(); // Exit app
                },
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Exit the app
    SystemNavigator.pop();
  }

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
                  color: isSelected
                      ? Colors.white
                      : AppColors.balckClr.withOpacity(0.6),
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
        if (index != widget.currentIndex) {
          context.go(_tabs[index]['route'] as String);
        }
      },
    );
  }

  IconData _fallbackIcon(int index) => [
    FeatherIcons.home,
    FeatherIcons.checkSquare,
    FeatherIcons.star,
    FeatherIcons.settings,
    FeatherIcons.moreHorizontal,
  ][index];
}
