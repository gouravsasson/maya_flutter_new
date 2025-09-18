import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:my_flutter_app/features/authentication/presentation/pages/call_sessions.dart';
import 'package:my_flutter_app/features/authentication/presentation/pages/home_page.dart';
import 'package:my_flutter_app/features/authentication/presentation/pages/integration_page.dart';
import 'package:my_flutter_app/features/authentication/presentation/pages/profile_page.dart';
import 'package:my_flutter_app/features/authentication/presentation/pages/tasks_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class TabLayout extends StatefulWidget {
  const TabLayout({super.key});

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
    });

    // Request contacts permission when the widget is initialized
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   PermissionHandler.requestContactsPermission(context);
    // });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method to handle logout
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove both access and refresh tokens
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    // Navigate to GoogleSignInScreen
    if (mounted) {
      context.go('/login');
    }
  }

  // Get the title for the current tab
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
              // Handle notification action
              // Add notification logic here
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: FeatherIcons.phone,
              title: 'Call Sessions',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CallSessionsPage(),
                  ),
                );
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
                // Navigate to help page
              },
            ),
            _buildDrawerItem(
              icon: FeatherIcons.info,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
                // Show about dialog
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          HomePage(),
          TasksPage(),
          IntegrationsPage(),
          // SettingsPage(),
        ],
      ),
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
