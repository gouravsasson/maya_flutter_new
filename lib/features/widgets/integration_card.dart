import 'package:flutter/material.dart';
import 'integration.dart';

class IntegrationCard extends StatelessWidget {
  final Integration integration;
  final VoidCallback onConnect;
  final VoidCallback onReset;

  const IntegrationCard({
    super.key,
    required this.integration,
    required this.onConnect,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding for compactness
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48, // Slightly smaller icon container
                height: 48,
                decoration: BoxDecoration(
                  color: integration.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  integration.icon,
                  size: 24, // Slightly smaller icon
                  color: integration.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            integration.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis, // Prevent text overflow
                          ),
                        ),
                        if (integration.connected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      integration.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2, // Limit description to 2 lines
                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180), // Limit button area width
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (integration.connected)
                      OutlinedButton(
                        onPressed: onReset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(80, 36), // Smaller button size
                        ),
                        child: const Text('Reset'),
                      ),
                    FilledButton(
                      onPressed: onConnect,
                      style: FilledButton.styleFrom(
                        backgroundColor: integration.connected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(80, 36), // Smaller button size
                      ),
                      child: Text(integration.connected ? 'Connect Another' : 'Connect'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}