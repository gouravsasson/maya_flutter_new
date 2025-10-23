import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_event.dart';
import '../../../features/authentication/presentation/pages/home_page.dart';
import '../../../features/authentication/presentation/pages/tasks_page.dart';
import '../../../features/authentication/presentation/pages/settings_page.dart';
import '../../../features/widgets/talk_to_maya.dart';
import '../../../features/authentication/presentation/pages/other_page.dart';

// Define static color constants to avoid method invocation in constant expressions
const Color inactiveGradientStart = Color(0x66FFFFFF); // White with 40% opacity
const Color inactiveGradientEnd = Color(0x33FFFFFF); // White with 20% opacity

class TabLayout extends StatefulWidget {
  final Widget child;

  const TabLayout({super.key, required this.child});

  @override
  _TabLayoutState createState() => _TabLayoutState();
}

class _TabLayoutState extends State<TabLayout> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  // List of routes in the order of tabs
  final List<String> _tabRoutes = [
    '/home',
    '/tasks',
    '/maya',
    '/settings',
    '/other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pageController = PageController(initialPage: 0);

    // Sync TabController with route changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
        // Navigate to the corresponding route
        context.go(_tabRoutes[_tabController.index]);
        // Sync PageView with TabController
        _pageController.jumpToPage(_tabController.index);
      }
    });

    // Sync PageView with swipes
    _pageController.addListener(() {
      if (_pageController.page != null) {
        int newIndex = _pageController.page!.round();
        if (_currentIndex != newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
          _tabController.animateTo(newIndex);
          context.go(_tabRoutes[newIndex]);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateTabFromRoute() {
    final location = GoRouterState.of(context).uri.path;
    int newIndex = _tabRoutes.indexOf(location);
    if (newIndex == -1) newIndex = 0; // Default to home if route not found

    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
      _tabController.animateTo(newIndex);
      _pageController.jumpToPage(newIndex);
    }
  }

  Future<bool> _onPopInvoked() async {
    final currentLocation = GoRouterState.of(context).uri.path;
    if (_tabRoutes.contains(currentLocation)) {
      if (currentLocation == '/home') {
        return true;
      }
      context.go('/home');
      return false;
    }
    return true;
  }

  Future<void> _handleLogout() async {
    context.read<AuthBloc>().add(LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTabFromRoute();
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onPopInvoked();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(), // Prevents overscroll bounce
          onPageChanged: (index) {
            // Handled in _pageController listener
          },
          children: const [
            HomePage(),
            TasksPage(),
            TalkToMaya(),
            SettingsPage(),
            OtherPage(),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(FeatherIcons.home, 'Home', 0, '/home'),
              _buildNavItem(FeatherIcons.checkSquare, 'Tasks', 1, '/tasks'),
              _buildCentralButton(),
              _buildNavItem(FeatherIcons.settings, 'Settings', 3, '/settings'),
              _buildNavItem(FeatherIcons.moreHorizontal, 'other', 4, '/other'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, String route) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          _tabController.animateTo(index);
          _pageController.jumpToPage(index); // Sync PageView with tap
          context.go(route);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue[100]?.withOpacity(0.6) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralButton() {
    final isActive = _currentIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
        _tabController.animateTo(2);
        _pageController.jumpToPage(2); // Sync PageView with tap
        context.go('/maya');
      },
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [inactiveGradientStart, inactiveGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.blue[400]!.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: const Icon(
            FeatherIcons.star,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}