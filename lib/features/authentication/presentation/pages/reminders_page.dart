import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final List<Map<String, dynamic>> reminders = List.generate(
    5,
    (index) => {
      'title': 'Reminder ${index + 1}',
      'description': 'Event on ${DateTime.now().add(Duration(days: index)).toString().split('.')[0]}',
      'dismissed': false,
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // gray-800
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Set and manage all your reminders',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4B5563), // gray-600
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Reminders List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_off,
                                color: reminders[index]['dismissed']
                                    ? const Color(0xFFD97706) // amber-700
                                    : const Color(0xFF6B7280), // gray-500
                              ),
                              onPressed: () {
                                setState(() {
                                  reminders[index]['dismissed'] = !reminders[index]['dismissed'];
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reminders[index]['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1F2937),
                                      decoration: reminders[index]['dismissed']
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reminders[index]['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}