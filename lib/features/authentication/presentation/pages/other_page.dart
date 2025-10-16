import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OtherPage extends StatelessWidget {
  const OtherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD), // blue-100
                  Color(0xFFF3E8FF), // purple-100
                  Color(0xFFFDE2F3), // pink-100
                ],
              ),
            ),
          ),
          // Radial gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Color(0x66BBDEFB), // blue-200/40
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Other',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // gray-800
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Additional features and settings',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4B5563), // gray-600
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Profile Section
                  _buildProfileSection(context),
                  const SizedBox(height: 16),
                  // Feature Tiles
                  _buildFeatureTiles(context),
                  const SizedBox(height: 16),
                  // Quick Links
                  _buildQuickLinks(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFFA855F7)], // blue-400 to purple-500
              ),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
            ),
            child: const Center(
              child: Text(
                'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Name',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'user@example.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x66BFDBFE), // blue-100/60
                    foregroundColor: const Color(0xFF3B82F6), // blue-700
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0x6693C5FD)), // blue-200/60
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTiles(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildFeatureTile(
          context: context,
          route: '/generations',
          icon: Icons.star_border,
          iconColor: const Color(0xFFA855F7), // purple-700
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66E9D5FF), Color(0x66F3E8FF)], // purple-200/40 to purple-100/40
          ),
          borderColor: const Color(0x66D8B4FE), // purple-300/60
          title: 'Generations',
          subtitle: 'View all AI-generated content and history',
        ),
        _buildFeatureTile(
          context: context,
          route: '/todos',
          icon: Icons.check_box_outline_blank,
          iconColor: const Color(0xFF047857), // green-700
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66BBF7D0), Color(0x66F0FDF4)], // green-200/40 to green-100/40
          ),
          borderColor: const Color(0x66BBF7D0), // green-300/60
          title: 'To-Dos',
          subtitle: 'Manage your personal to-do lists',
        ),
        _buildFeatureTile(
          context: context,
          route: '/reminders',
          icon: Icons.calendar_today,
          iconColor: const Color(0xFFD97706), // amber-700
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66FEF3C7), Color(0x66FFFBEB)], // amber-200/40 to amber-100/40
          ),
          borderColor: const Color(0x66FCD34D), // amber-300/60
          title: 'Reminders',
          subtitle: 'Set and manage all your reminders',
        ),
        _buildFeatureTile(
          context: context,
          route: '/integrations',
          icon: Icons.extension,
          iconColor: const Color(0xFF3B82F6), // blue-700
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66BFDBFE), Color(0x66EFF6FF)], // blue-200/40 to blue-100/40
          ),
          borderColor: const Color(0x6693C5FD), // blue-300/60
          title: 'Integrations',
          subtitle: 'Connect Google, CRMs, and other services',
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required BuildContext context,
    required String route,
    required IconData icon,
    required Color iconColor,
    required LinearGradient backgroundGradient,
    required Color borderColor,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: backgroundGradient.colors[0],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: const Color(0xFF6B7280), // gray-500
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Links',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickLinkTile(context, 'Help & Support', '/help'),
          const SizedBox(height: 8),
          _buildQuickLinkTile(context, 'About Maya', '/about'),
          const SizedBox(height: 8),
          _buildQuickLinkTile(context, 'Terms & Privacy', '/terms'),
        ],
      ),
    );
  }

  Widget _buildQuickLinkTile(BuildContext context, String title, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151), // gray-700
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: const Color(0xFF6B7280), // gray-500
            ),
          ],
        ),
      ),
    );
  }
}