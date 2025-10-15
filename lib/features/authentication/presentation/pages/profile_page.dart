import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        print('🔍 Profile Page: User data - ${user?.firstName}');

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: const Color(0xFF1F2937), // gray-800
              onPressed: () => context.go('/other'),
            ),
          ),
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
                child: user == null
                    ? const Center(
                        child: Text(
                          'No user data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937), // gray-800
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your account details',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4B5563), // gray-600
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Profile Picture
                            Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF60A5FA), Color(0xFFA855F7)], // blue-400 to purple-500
                                  ),
                                  boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                                ),
                                child: Center(
                                  child: Text(
                                    user.firstName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // User Info Card
                            Container(
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
                                    'User Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    Icons.person,
                                    'Name',
                                    user.firstName,
                                    const Color(0xFF3B82F6), // blue-700
                                  ),
                                  _buildInfoRow(
                                    Icons.email,
                                    'Email',
                                    user.email,
                                    const Color(0xFF3B82F6),
                                  ),
                                  _buildInfoRow(
                                    Icons.perm_identity,
                                    'User ID',
                                    user.id,
                                    const Color(0xFF3B82F6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // GoRouter Info Card
                            Container(
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
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.router,
                                        color: Color(0xFFA855F7), // purple-700
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'GoRouter Navigation',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    Icons.link,
                                    'Current Route',
                                    GoRouterState.of(context).uri.toString(),
                                    const Color(0xFFA855F7),
                                  ),
                                  _buildInfoRow(
                                    Icons.navigation,
                                    'Route Name',
                                    GoRouterState.of(context).name ?? 'N/A',
                                    const Color(0xFFA855F7),
                                  ),
                                  _buildInfoRow(
                                    Icons.history,
                                    'Navigation Method',
                                    'context.push() or context.go()',
                                    const Color(0xFFA855F7),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Navigation Demo Buttons
                            Container(
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
                                    'Navigation Demo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.go('/home'),
                                          icon: const Icon(Icons.home),
                                          label: const Text('Go Home'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0x66BFDBFE), // blue-100/60
                                            foregroundColor: const Color(0xFF3B82F6), // blue-700
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: const BorderSide(color: Color(0x6693C5FD)), // blue-200/60
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.pop(),
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Pop Back'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0x66D1D5DB), // gray-300/60
                                            foregroundColor: const Color(0xFF6B7280), // gray-500
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: const BorderSide(color: Color(0x66D1D5DB)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Logout Button
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _showLogoutDialog(context),
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0x66FECACA), // rose-100/60
                                  foregroundColor: const Color(0xFFBE123C), // rose-700
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Color(0x66FCA5A5)), // rose-200/60
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937), // gray-800
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF4B5563), // gray-600
                fontFamily: value.startsWith('/') ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.logout, color: Color(0xFFD97706)), // amber-700
                const SizedBox(width: 8),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to logout?\n\nYou will be redirected to the login page.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x66E5E7EB), // gray-200/60
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x66FECACA), // rose-100/60
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBE123C), // rose-700
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}