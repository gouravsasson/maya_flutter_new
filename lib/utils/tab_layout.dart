import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

// Modified TabLayout that works with ShellRoute
class TabLayout extends StatefulWidget {
  final Widget child; // Accept child from ShellRoute
  
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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
      
      // Navigate to corresponding route when tab changes
      switch (_tabController.index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/tasks');
          break;
        case 2:
          context.go('/integrations');
          break;
        case 3:
          // Add settings route if needed
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Update tab controller based on current route
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
      case '/integrations':
        newIndex = 2;
        break;
      default:
        newIndex = 0;
    }
    
    if (_currentIndex != newIndex) {
      _currentIndex = newIndex;
      _tabController.animateTo(newIndex);
    }
  }

  // Method to handle logout (same as before)
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    if (mounted) {
      context.go('/login');
    }
  }

  // Get the title for the current tab (same as before)
  String _getTabTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Tasks';
      case 2:
        return 'Integrations';
      case 3:
        return 'Settings';
      default:
        return 'Maya App';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update tab based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTabFromRoute();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTabTitle()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(FeatherIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.bell, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications clicked')),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      FeatherIcons.user,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Maya Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AI-Powered Productivity',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: FeatherIcons.user,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile'); // Use GoRouter navigation
              },
            ),
            _buildDrawerItem(
              icon: FeatherIcons.phone,
              title: 'Call Sessions',
              onTap: () {
                Navigator.pop(context);
                context.go('/call_sessions'); // Use GoRouter navigation
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            _buildDrawerItem(
              icon: FeatherIcons.helpCircle,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: FeatherIcons.info,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              icon: FeatherIcons.logOut,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
      body: widget.child, // Show the child from GoRouter instead of TabBarView
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            indicator: const BoxDecoration(),
            indicatorPadding: EdgeInsets.zero,
            tabs: [
              _buildTab(FeatherIcons.home, 'Home', 0),
              _buildTab(FeatherIcons.checkSquare, 'Tasks', 1),
              _buildTab(FeatherIcons.zap, 'Connect', 2),
              _buildTab(FeatherIcons.settings, 'Robot', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF6366F1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}