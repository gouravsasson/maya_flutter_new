import 'package:Maya/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

// ------------------------------------------------------------------
// USER MODEL – matches your API response
// ------------------------------------------------------------------
class User {
  final int? id; // <-- Now nullable
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String apiKey;
  final String deviceId;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.apiKey,
    required this.deviceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['data']['data'] as Map<String, dynamic>;
    print(data);
    return User(
      id: data['ID'] as int?, // <-- Safe cast
      firstName: data['first_name'] as String,
      lastName: data['last_name'] as String,
      email: data['email'] as String,
      phoneNumber: data['phone_number'] as String,
      apiKey: data['api_key'] as String,
      deviceId: data['device_id'] as String,
    );
  }

  String get fullName => '$firstName $lastName';
  String get initials =>
      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
}

// ------------------------------------------------------------------
// OTHER PAGE – fetches user from ApiClient
// ------------------------------------------------------------------
class OtherPage extends StatefulWidget {
  const OtherPage({super.key});

  @override
  State<OtherPage> createState() => _OtherPageState();
}

class _OtherPageState extends State<OtherPage> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      // Use your real ApiClient
      final result = await GetIt.I<ApiClient>().getCurrentUser();

      if (result['statusCode'] == 200 && result['data']['success'] == true) {
        setState(() {
          _user = User.fromJson(result);
          _isLoading = false;
        });
      } else {
        throw Exception(result['data']['message'] ?? 'Failed to load user');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
                  Color(0xFFE3F2FD),
                  Color(0xFFF3E8FF),
                  Color(0xFFFDE2F3),
                ],
              ),
            ),
          ),
          // Radial overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0x66BBDEFB), Colors.transparent],
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
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Additional features and settings',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 24),

                  // Profile Section – Real Data
                  _buildProfileSection(context),

                  const SizedBox(height: 16),
                  _buildFeatureTiles(context),
                  const SizedBox(height: 16),
                  _buildQuickLinks(context),
                ],
              ),
            ),
          ),

          // Loading / Error Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load user: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // PROFILE SECTION – uses real user data
  // --------------------------------------------------------------
  Widget _buildProfileSection(BuildContext context) {
    final name = _user?.fullName ?? 'User Name';
    final email = _user?.email ?? 'user@example.com';
    final avatarLetter = _user?.initials ?? 'U';

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
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
              ),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black26),
              ],
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x66BFDBFE),
                    foregroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0x6693C5FD)),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // FEATURE TILES (unchanged)
  // --------------------------------------------------------------
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
          iconColor: const Color(0xFFA855F7),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66E9D5FF), Color(0x66F3E8FF)],
          ),
          borderColor: const Color(0x66D8B4FE),
          title: 'Generations',
          subtitle: 'View all AI-generated content and history',
        ),
        _buildFeatureTile(
          context: context,
          route: '/todos',
          icon: Icons.check_box_outline_blank,
          iconColor: const Color(0xFF047857),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66BBF7D0), Color(0x66F0FDF4)],
          ),
          borderColor: const Color(0x66BBF7D0),
          title: 'To-Dos',
          subtitle: 'Manage your personal to-do lists',
        ),
        _buildFeatureTile(
          context: context,
          route: '/reminders',
          icon: Icons.calendar_today,
          iconColor: const Color(0xFFD97706),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66FEF3C7), Color(0x66FFFBEB)],
          ),
          borderColor: const Color(0x66FCD34D),
          title: 'Reminders',
          subtitle: 'Set and manage all your reminders',
        ),
        _buildFeatureTile(
          context: context,
          route: '/integrations',
          icon: Icons.extension,
          iconColor: const Color(0xFF3B82F6),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66BFDBFE), Color(0x66EFF6FF)],
          ),
          borderColor: const Color(0x6693C5FD),
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
                  child: Center(child: Icon(icon, size: 28, color: iconColor)),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Color(0xFF6B7280),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // QUICK LINKS
  // --------------------------------------------------------------
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
              style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
