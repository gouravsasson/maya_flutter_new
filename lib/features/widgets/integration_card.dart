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

  Widget getStatusBadge(bool isConnected) {
    final statusConfig = {
      true: {
        'label': 'Connected',
        'icon': Icons.check_circle,
        'bgColor': const Color(0xFF10B981).withOpacity(0.2),
        'borderColor': const Color(0xFF10B981).withOpacity(0.3),
        'textColor': const Color(0xFF10B981),
      },
      false: {
        'label': 'Not Connected',
        'bgColor': const Color(0xFFF59E0B).withOpacity(0.2),
        'borderColor': const Color(0xFFF59E0B).withOpacity(0.3),
        'textColor': const Color(0xFFF59E0B),
        'icon': Icons.link_off,
      },
    };

    final config = statusConfig[isConnected]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['bgColor'] as Color,
        border: Border.all(color: config['borderColor'] as Color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 14,
            color: config['textColor'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config['textColor'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Kept for potential future interactivity
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: integration.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          integration.icon,
                          size: 24,
                          color: integration.iconColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          integration.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                getStatusBadge(integration.connected),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              integration.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (integration.connected)
                  GestureDetector(
                    onTap: onReset,
                    child: Row(
                      children: [
                        Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.red[700],
                        ),
                      ],
                    ),
                  ),
                if (integration.connected) const SizedBox(width: 16),
                GestureDetector(
                  onTap: onConnect,
                  child: Row(
                    children: [
                      Text(
                        integration.connected ? 'Connect Another' : 'Connect',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}