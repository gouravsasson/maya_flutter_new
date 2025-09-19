// lib/features/home/presentation/pages/widgets/features_section.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Maya/features/widgets/features_card.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  void _showFeatureInfo(
    BuildContext context,
    String title,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GoRouter Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            FeatureCard(
              icon: Icons.link,
              title: 'URL Support',
              description: 'Web-friendly URLs',
              color: Colors.blue,
              onTap: () => _showFeatureInfo(
                context,
                'URL Support',
                'GoRouter provides excellent web support with proper URLs that work in browsers.',
              ),
            ),
            FeatureCard(
              icon: Icons.security,
              title: 'Route Guards',
              description: 'Built-in protection',
              color: Colors.green,
              onTap: () => _showFeatureInfo(
                context,
                'Route Guards',
                'Automatic route protection through redirect logic - no manual guards needed!',
              ),
            ),
            FeatureCard(
              icon: Icons.navigation,
              title: 'Declarative',
              description: 'Modern routing',
              color: Colors.orange,
              onTap: () => _showFeatureInfo(
                context,
                'Declarative Routing',
                'Define your routes declaratively with automatic navigation handling.',
              ),
            ),
            FeatureCard(
              icon: Icons.speed,
              title: 'Performance',
              description: 'Optimized navigation',
              color: Colors.purple,
              onTap: () => _showFeatureInfo(
                context,
                'Performance',
                'GoRouter is optimized for performance with efficient route management.',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/ghl'); // ✅ Navigate with GoRouter
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.web),
              label: const Text("Open GoHighLevel"),
            ),
          ],
        ),
      ],
    );
  }
}
