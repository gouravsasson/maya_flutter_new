import 'package:Maya/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Map<String, dynamic>> reminders = [];
  bool isLoadingReminders = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchReminders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchReminders({int page = 1}) async {
    if (page == 1) {
      setState(() => isLoadingReminders = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    try {
      final response = await GetIt.I<ApiClient>().getReminders(page: page);
      if (response['statusCode'] == 200) {
        final newReminders = List<Map<String, dynamic>>.from(response['data']['data']);
        setState(() {
          if (page == 1) {
            reminders = newReminders;
          } else {
            reminders.addAll(newReminders);
          }
          hasMore = newReminders.isNotEmpty; // Assuming API returns empty list when no more data
          currentPage = page;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch reminders: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reminders: $e')),
      );
    } finally {
      setState(() {
        isLoadingReminders = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      fetchReminders(page: currentPage + 1);
    }
  }

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
            child: isLoadingReminders
                ? const Center(child: CircularProgressIndicator())
                : reminders.isEmpty
                    ? const Center(child: Text('No reminders available', style: TextStyle(color: Colors.grey)))
                    : SingleChildScrollView(
                        controller: _scrollController,
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
                              itemCount: reminders.length + (isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == reminders.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final utcTime = DateTime.parse(reminders[index]['reminder_time']);
                                final localTime = utcTime.toLocal();
                                final formattedTime = DateFormat('MMM d, yyyy h:mm a').format(localTime);
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
                                      const Icon(
                                        Icons.notifications,
                                        color: Color(0xFF6B7280), // gray-500
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reminders[index]['title'] ?? 'Reminder',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedTime,
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