import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:Maya/core/network/api_client.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import 'package:Maya/core/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class TaskDetail {
  final String id;
  final String query;
  final String status;
  final String error;
  final String timestamp;

  TaskDetail({
    required this.id,
    required this.query,
    required this.status,
    required this.error,
    required this.timestamp,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    final toolCall = json['current_tool_call'] as Map<String, dynamic>? ?? {};
    final status =
        toolCall['status']?.toString() ?? json['status']?.toString() ?? '';
    final success =
        json['success'] as bool? ?? toolCall['success'] as bool? ?? false;
    final error =
        json['error']?.toString() ?? toolCall['error']?.toString() ?? '';

    String formattedTimestamp = 'No timestamp';
    try {
      final createdAt = DateTime.parse(json['created_at']?.toString() ?? '');
      formattedTimestamp = DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
    } catch (e) {
      // Keep default if parsing fails
    }

    return TaskDetail(
      id: json['id']?.toString() ?? 'Unknown',
      query:
          json['user_payload']?['task']?.toString() ??
          json['query']?.toString() ??
          'No query',
      status: status.isNotEmpty
          ? status
          : (success ? 'completed' : (error.isNotEmpty ? 'failed' : 'pending')),
      error: error.isNotEmpty ? error : 'None',
      timestamp: formattedTimestamp,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> reminders = [];
  List<TaskDetail> tasks = [];
  bool isLoadingTodos = false;
  bool isLoadingReminders = false;
  bool isLoadingTasks = false;
  NotificationServices notificationServices = NotificationServices();
  String? fcmToken;
  String? locationPermissionStatus;
  late ApiClient apiClient;

  @override
  void initState() {
    super.initState();
    final publicDio = Dio();
    final protectedDio = Dio();
    apiClient = ApiClient(publicDio, protectedDio);
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    notificationServices.isTokenRefresh();

    notificationServices.getDeviceToken().then((value) {
      setState(() => fcmToken = value);
      if (kDebugMode) {
        getIt<ApiClient>().sendFcmToken(value);
        print('device token: $value');
      }
    });
    fetchReminders();
    fetchToDos();
    fetchTasks();
    _initializeAndSaveLocation();
  }

  Future<void> _initializeAndSaveLocation() async {
    try {
      String timezone = (await FlutterTimezone.getLocalTimezone()) as String;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationPermissionStatus = 'Location services disabled');
        if (kDebugMode) print('Location services are disabled.');
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationPermissionStatus = 'Location permission denied');
        if (kDebugMode) print('Location permission status: Denied');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog();
          setState(
            () => locationPermissionStatus =
                'Location permission denied after request',
          );
          if (kDebugMode) {
            print('Location permission status: Denied after request');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => locationPermissionStatus =
              'Location permission permanently denied',
        );
        if (kDebugMode) print('Location permission status: Permanently denied');
        _showLocationPermissionDialog(permanent: true);
        return;
      }

      setState(() => locationPermissionStatus = 'Location permission granted');
      if (kDebugMode) print('Location permission status: Granted');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final response = await getIt<ApiClient>().saveLocation(
        position.latitude,
        position.longitude,
        timezone,
      );

      if (response['statusCode'] == 200) {
        if (kDebugMode) {
          print(
            'Location saved successfully: ${position.latitude}, ${position.longitude}, $timezone',
          );
        }
      } else {
        if (kDebugMode) print('Failed to save location: ${response['data']}');
      }
    } catch (e) {
      setState(
        () => locationPermissionStatus = 'Error checking permission: $e',
      );
      if (kDebugMode) print('Error saving location: $e');
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to save your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog({bool permanent = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: Text(
          permanent
              ? 'Location permissions are permanently denied. Please enable them in app settings.'
              : 'Location permission is required to save your location.',
        ),
        actions: [
          if (!permanent)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (permanent) {
                Geolocator.openAppSettings();
              } else {
                Geolocator.requestPermission();
              }
            },
            child: Text(permanent ? 'Open Settings' : 'Grant Permission'),
          ),
        ],
      ),
    );
  }

  Future<void> fetchReminders() async {
    setState(() => isLoadingReminders = true);
    try {
      final response = await getIt<ApiClient>().getReminders();
      if (response['statusCode'] == 200) {
        setState(() {
          reminders = List<Map<String, dynamic>>.from(response['data']['data']);
        });
      } else {
        if (kDebugMode)
          print('Failed to fetch reminders: ${response['message']}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching reminders: $e');
    }
    setState(() => isLoadingReminders = false);
  }

  Future<void> fetchToDos() async {
    setState(() => isLoadingTodos = true);
    final response = await getIt<ApiClient>().getToDo();
    if (response['statusCode'] == 200) {
      setState(
        () => todos = List<Map<String, dynamic>>.from(response['data']['data']),
      );
    }
    setState(() => isLoadingTodos = false);
  }

  Future<void> fetchTasks() async {
    setState(() => isLoadingTasks = true);
    try {
      final response = await apiClient.fetchTasks(page: 1);
      final data = response['data'];
      if (response['statusCode'] == 200 && data['success'] == true) {
        final List<dynamic> taskList =
            data['data']?['sessions'] as List<dynamic>? ?? [];
        setState(() {
          tasks = taskList.map((json) => TaskDetail.fromJson(json)).toList();
          isLoadingTasks = false;
        });
      } else {
        setState(() => isLoadingTasks = false);
        if (kDebugMode) {
          print('Failed to load tasks: ${data['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      setState(() => isLoadingTasks = false);
      if (kDebugMode) print('Error fetching tasks: $e');
    }
  }

  Future<void> addToDo(
    String title,
    String description, {
    String? reminder,
  }) async {
    final payload = getIt<ApiClient>().prepareCreateToDoPayload(
      title,
      description,
      reminder,
    );
    final response = await getIt<ApiClient>().createToDo(payload);
    if (response['statusCode'] == 200) fetchToDos();
  }

  Future<void> updateToDo(Map<String, dynamic> todo) async {
    final payload = getIt<ApiClient>().prepareUpdateToDoPayload(
      todo['ID'],
      title: todo['title'],
      description: todo['description'],
      status: todo['status'],
      reminder: todo['reminder'] ?? false,
      reminder_time: todo['reminder_time'],
    );
    final response = await getIt<ApiClient>().updateToDo(payload);
    if (response['statusCode'] == 200) {
      fetchToDos();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('To-Do updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update To-Do: ${response['message'] ?? 'Unknown error'}',
          ),
        ),
      );
    }
  }

  Future<void> completeToDo(Map<String, dynamic> todo) async {
    setState(() => isLoadingTodos = true);
    try {
      final payload = getIt<ApiClient>().prepareUpdateToDoPayload(
        todo['ID'],
        title: todo['title'],
        description: todo['description'],
        status: 'completed',
        reminder: todo['reminder'] ?? false,
        reminder_time: todo['reminder_time'],
      );
      final response = await getIt<ApiClient>().updateToDo(payload);
      if (response['statusCode'] == 200) {
        await fetchToDos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To-Do marked as completed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to complete To-Do: ${response['message'] ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing To-Do: $e')));
    } finally {
      setState(() => isLoadingTodos = false);
    }
  }

  Future<void> deleteToDo(int id) async {
    final response = await getIt<ApiClient>().deleteToDo(id);
    if (response['statusCode'] == 200) fetchToDos();
  }

  Future<void> sendNotification() async {
    final token = await notificationServices.getDeviceToken();
    var data = {
      'to': token,
      'notification': {
        'title': 'Maya App',
        'body': 'This is a test notification',
        'sound': 'jetsons_doorbell.mp3',
      },
      'android': {
        'notification': {'notification_count': 1},
      },
      'data': {'type': 'custom', 'id': '12345'},
    };

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        body: jsonEncode(data),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=YOUR_SERVER_KEY_HERE',
        },
      );
      if (kDebugMode) print("Notification response: ${response.body}");
    } catch (e) {
      if (kDebugMode) print("Error sending notification: $e");
    }
  }

  void copyFcmToken() {
    if (fcmToken != null) {
      Clipboard.setData(ClipboardData(text: fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    String greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDBEAFE), // blue-100
                  Color(0xFFF3E8FF), // purple-100
                  Color(0xFFFCE7F3), // pink-100
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    Color(0x66BFDBFE), // blue-200 with 40% opacity
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        '$greeting, ${"User"}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Here's what's happening today",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Recent Activity Section
                      _buildSection(
                        title: 'Recent Activity',
                        icon: LucideIcons.clock,
                        color: Colors.purple,
                        children: [
                          _buildActivityItem({
                            'type': 'success',
                            'action': 'Completed task',
                            'detail': 'Update website design',
                            'time': '5h ago',
                          }),
                          _buildActivityItem({
                            'type': 'info',
                            'action': 'New task assigned',
                            'detail': 'Prepare quarterly report',
                            'time': '3h ago',
                          }),
                          _buildActivityItem({
                            'type': 'error',
                            'action': 'Task failed',
                            'detail': 'Book meeting with client',
                            'time': '1d ago',
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active Tasks Section
                      _buildSection(
                        title: 'Active Tasks',
                        icon: LucideIcons.zap,
                        color: Colors.blue,
                        children: isLoadingTasks
                            ? [const Center(child: CircularProgressIndicator())]
                            : tasks.isEmpty
                                ? [
                                    const Text(
                                      'No active tasks',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ]
                                : tasks.take(3).map((task) {
                                    return _buildTaskItem(task);
                                  }).toList(),
                        trailing: TextButton(
                          onPressed: () => context.go('/tasks'),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upcoming Section
                      _buildSection(
                        title: 'Upcoming',
                        icon: LucideIcons.calendar,
                        color: Colors.amber,
                        children: isLoadingReminders
                            ? [const Center(child: CircularProgressIndicator())]
                            : reminders.isEmpty
                                ? [
                                    const Text(
                                      'No upcoming reminders',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ]
                                : reminders.take(3).map((reminder) {
                                    return _buildReminderItem(reminder);
                                  }).toList(),
                        trailing: TextButton(
                          onPressed: () => context.go('/todos'),
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // To-Do Section
                      _buildSection(
                        title: 'To-Do',
                        icon: LucideIcons.checkSquare,
                        color: Colors.green,
                        children: isLoadingTodos
                            ? [const Center(child: CircularProgressIndicator())]
                            : todos.isEmpty
                                ? [
                                    const Text(
                                      'No to-dos available',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ]
                                : todos.take(3).map((todo) {
                                    return _buildToDoItem(todo);
                                  }).toList(),
                        trailing: TextButton(
                          onPressed: () => context.go('/reminders'),
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    Color dotColor = activity['type'] == 'success'
        ? Colors.green
        : activity['type'] == 'error'
            ? Colors.red
            : Colors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${activity['action']} - ${activity['detail']}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            activity['time'],
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskDetail task) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (task.status.toLowerCase()) {
      case 'succeeded':
      case 'completed':
        statusColor = Colors.green;
        statusLabel = 'Completed';
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusLabel = 'Failed';
        statusIcon = LucideIcons.xCircle;
        break;
      case 'approval_pending':
        statusColor = Colors.blue;
        statusLabel = 'Needs Approval';
        statusIcon = LucideIcons.alertCircle;
        break;
      case 'pending':
      default:
        statusColor = Colors.amber;
        statusLabel = 'In Progress';
        statusIcon = LucideIcons.clock;
        break;
    }

    return GestureDetector(
      onTap: () {
        context.go(
          '/tasks/${task.id}',
          extra: {'query': task.query},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.zap,
                  size: 16,
                  color: Colors.blue.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.query.isNotEmpty ? task.query : 'No query provided',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  task.timestamp,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (task.error != 'None') ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${task.error}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    final utcTime = DateTime.parse(reminder['reminder_time']);
    final localTime = utcTime.toLocal();
    final formattedTime = DateFormat('MMM d, yyyy h:mm a').format(localTime);

    return GestureDetector(
      onTap: () => context.go('/other'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder['title'] ?? 'Reminder',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToDoItem(Map<String, dynamic> todo) {
    return GestureDetector(
      onTap: todo['status'] == 'completed' ? null : () => completeToDo(todo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: todo['status'] == 'completed'
                  ? null
                  : () => completeToDo(todo),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: todo['status'] == 'completed'
                        ? Colors.green
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: todo['status'] == 'completed'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: todo['status'] == 'completed'
                    ? const Icon(
                        LucideIcons.checkCircle2,
                        size: 14,
                        color: Colors.green,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo['title'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  decoration: todo['status'] == 'completed'
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.grey,
                ),
              ),
            ),
            if (todo['status'] != 'completed' && todo['priority'] == 'high')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'High',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?\n\nGoRouter will automatically redirect you to the login page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}