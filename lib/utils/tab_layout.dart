import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_event.dart';
import '../../../config/routes/app_router.dart';

class TabLayout extends StatefulWidget {
  final Widget child;

  const TabLayout({super.key, required this.child});

  @override
  State<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends State<TabLayout> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  DateTime? _lastBackPress;
  bool _isNavigating = false;

  static const List<Map<String, dynamic>> _tabs = [
    {'route': '/home', 'icon': FeatherIcons.home, 'label': 'Home'},
    {'route': '/tasks', 'icon': FeatherIcons.checkSquare, 'label': 'Tasks'},
    {'route': '/maya', 'icon': FeatherIcons.star, 'label': 'Maya'},
    {'route': '/settings', 'icon': FeatherIcons.settings, 'label': 'Settings'},
    {'route': '/other', 'icon': FeatherIcons.moreHorizontal, 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialize with current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTabWithRoute();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTabWithRoute();
  }

  void _handleTabChange() {
    if (_isNavigating) return;
    
    if (_tabController.indexIsChanging || _tabController.index != _currentIndex) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      
      final route = _tabs[_currentIndex]['route'] as String;
      debugPrint('🔄 TabLayout: Tab changed to index $_currentIndex -> $route');
      
      _isNavigating = true;
      context.go(route);
      
      // Reset flag after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
      });
    }
  }

  void _syncTabWithRoute() {
    try {
      final location = GoRouterState.of(context).uri.path;
      final newIndex = _findTabIndexForRoute(location);
      
      if (newIndex != -1 && newIndex != _currentIndex) {
        debugPrint('🔄 TabLayout: Syncing tab to match route $location (index $newIndex)');
        setState(() {
          _currentIndex = newIndex;
        });
        
        if (_tabController.index != newIndex) {
          _tabController.animateTo(newIndex);
        }
      }
    } catch (e) {
      debugPrint('⚠️ TabLayout: Error syncing route: $e');
    }
  }

  int _findTabIndexForRoute(String location) {
    // Exact match first
    final exactIndex = _tabs.indexWhere((tab) => location == tab['route']);
    if (exactIndex != -1) return exactIndex;
    
    // Then check if location starts with tab route (for nested routes)
    final nestedIndex = _tabs.indexWhere(
      (tab) => location.startsWith('${tab['route']}/'),
    );
    
    return nestedIndex;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Production-grade back button handler
  Future<bool> _handleBackButton() async {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isMainTab = AppRouter.isMainTab(currentLocation);
    
    debugPrint('⬅️ TabLayout: Back pressed');
    debugPrint('   Current: $currentLocation');
    debugPrint('   Is main tab: $isMainTab');
    debugPrint('   Can go back: ${AppRouter.navigationHistory.canGoBack()}');
    debugPrint('   History: ${AppRouter.navigationHistory.fullHistory}');

    // If we have navigation history, use it
    if (AppRouter.navigationHistory.canGoBack()) {
      final success = await AppRouter.goBack(context);
      if (success) {
        debugPrint('✅ TabLayout: Navigated back successfully');
        return true; // Prevent default back action
      }
    }

    // No history - we're at the first route
    // Implement "press back twice to exit" on main tabs
    if (isMainTab) {
      final now = DateTime.now();
      
      if (_lastBackPress == null || 
          now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
        _lastBackPress = now;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(
                bottom: 100, 
                left: 16, 
                right: 16,
              ),
            ),
          );
        }
        
        return true; // Prevent exit on first press
      } else {
        // Second press within 2 seconds - allow exit
        debugPrint('👋 TabLayout: Exiting app');
        return false; // Allow app to close
      }
    }

    // Not on main tab and no history - shouldn't happen, but allow back
    debugPrint('⚠️ TabLayout: Unexpected state - allowing back');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPreventPop = await _handleBackButton();
        
        if (!shouldPreventPop && mounted) {
          // Allow the app to close
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        extendBody: true,
        body: widget.child,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    const activeColor = Color(0xFF60A5FA);
    const inactiveColor = Color(0xFF9CA3AF);
    const backgroundColor = Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.all(16),
      height: 90,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom navigation bar with notch
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _NavBarNotchPainter(),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      final isActive = _currentIndex == index;
                      final isCentral = index == 2;

                      if (isCentral) {
                        return const Expanded(child: SizedBox());
                      }

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_currentIndex != index) {
                              _tabController.animateTo(index);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tab['icon'] as IconData,
                                  size: 22,
                                  color: isActive ? activeColor : inactiveColor,
                                ),
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
            ),
          ),
          
          // Elevated central FAB
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentIndex != 2) {
                  _tabController.animateTo(2);
                }
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
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        FeatherIcons.star,
                        color: Colors.white,
                        size: 28,
                      );
                    },
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

class _NavBarNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    
    final notchCenter = size.width / 2;
    final notchRadius = 38.0;
    
    path.moveTo(notchCenter - notchRadius - 10, 0);
    path.quadraticBezierTo(
      notchCenter - notchRadius, -5,
      notchCenter - notchRadius + 5, -10,
    );
    
    path.arcToPoint(
      Offset(notchCenter + notchRadius - 5, -10),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    
    path.quadraticBezierTo(
      notchCenter + notchRadius, -5,
      notchCenter + notchRadius + 10, 0,
    );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}