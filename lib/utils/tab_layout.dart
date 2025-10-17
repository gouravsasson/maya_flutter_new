import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_event.dart';

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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });

        switch (_tabController.index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/tasks');
            break;
          case 2:
            context.go('/maya');
            break;
          case 3:
            context.go('/settings');
            break;
          case 4:
            context.go('/other');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabFromRoute() {
    final location = GoRouterState.of(context).uri.path;
    int newIndex = 0;

    switch (location) {
      case '/home':
        newIndex = 0;
        break;
      case '/tasks':
        newIndex = 1;
        break;
      case '/maya':
        newIndex = 2;
        break;
      case '/settings':
        newIndex = 3;
        break;
      case '/other':
        newIndex = 4;
        break;
      default:
        newIndex = 0;
    }

    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
      _tabController.animateTo(newIndex);
    }
  }

  Future<bool> _onPopInvoked() async {
    final currentLocation = GoRouterState.of(context).uri.path;
    if (currentLocation == '/home' ||
        currentLocation == '/tasks' ||
        currentLocation == '/maya' ||
        currentLocation == '/settings' ||
        currentLocation == '/other') {
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
        backgroundColor: Colors.transparent, // Make scaffold background transparent
        body: widget.child,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          decoration: BoxDecoration(
            // Remove solid color, use transparent or gradient
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
                : LinearGradient(
                    colors: [const Color(0x66FFFFFF), const Color(0x33FFFFFF)],
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
          child: Icon(
            FeatherIcons.star,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}