import 'dart:convert';
import 'package:Maya/features/widgets/generations.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Add this dependency: geolocator: ^10.1.0 in pubspec.yaml
import 'package:flutter_timezone/flutter_timezone.dart'; // Add this dependency: flutter_timezone: ^1.0.8 in pubspec.yaml
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/features/widgets/features_section.dart';
import 'package:Maya/features/widgets/go_router_demo.dart';
import 'package:Maya/features/widgets/talk_to_maya.dart';
import 'package:Maya/features/widgets/todo_list.dart';
import 'package:Maya/features/widgets/welcome_card.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import 'package:Maya/core/services/notification_service.dart';
import 'package:Maya/features/widgets/google_search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> reminders = [];
  bool isLoadingTodos = false;
  bool isLoadingReminders = false;
  NotificationServices notificationServices = NotificationServices();
  String? fcmToken; // Store FCM token
  String? locationPermissionStatus; // ✅ Track permission status

  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    notificationServices.isTokenRefresh();

    // Fetch and store FCM token
    notificationServices.getDeviceToken().then((value) {
      setState(() {
        fcmToken = value;
      });
      if (kDebugMode) {
        getIt<ApiClient>().sendFcmToken(value);
        print('device token: $value');
      }
    });
    fetchReminders();
    fetchToDos();
    // Initialize and save location on page load
    _initializeAndSaveLocation();
  }

  // ✅ Initialize and fetch current location + timezone, then save it
  Future<void> _initializeAndSaveLocation() async {
    try {
      // Get the device's local timezone
      TimezoneInfo timezone = await FlutterTimezone.getLocalTimezone();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationPermissionStatus = 'Location services disabled');
        if (kDebugMode) print('Location services are disabled.');
        _showLocationServiceDialog();
        return;
      }

      // Check and request location permissions
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save location via API
      final response = await getIt<ApiClient>().saveLocation(
        position.latitude,
        position.longitude,
        timezone as String,
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

  // ✅ Dialog to prompt enabling location services
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

  // ✅ Dialog to request location permissions
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
          if (!permanent) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
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
    final response = await getIt<ApiClient>().fetchReminders();
    if (response['statusCode'] == 200) {
      setState(() {
        reminders = List<Map<String, dynamic>>.from(response['data']);
      });
      if (kDebugMode) print("reminders: $reminders");
    }
    setState(() => isLoadingReminders = false);
  }

  // ✅ Fetch ToDos using ApiClient
  Future<void> fetchToDos() async {
    setState(() => isLoadingTodos = true);
    final response = await getIt<ApiClient>().getToDo();
    if (response['statusCode'] == 200) {
      setState(() {
        todos = List<Map<String, dynamic>>.from(response['data']['data']);
      });
    }
    setState(() => isLoadingTodos = false);
  }

  // ✅ Add ToDo
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
    if (response['statusCode'] == 200) {
      fetchToDos();
    }
  }

  // ✅ Update ToDo
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
    }
  }

  // ✅ Delete ToDo
  Future<void> deleteToDo(int id) async {
    final response = await getIt<ApiClient>().deleteToDo(id);
    if (response['statusCode'] == 200) {
      fetchToDos();
    }
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
          'Authorization':
              'key=YOUR_SERVER_KEY_HERE', // 🔑 Replace with your FCM server key
        },
      );
      if (kDebugMode) print("Notification response: ${response.body}");
    } catch (e) {
      if (kDebugMode) print("Error sending notification: $e");
    }
  }

  // Copy FCM token to clipboard
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WelcomeCard(),
                    const SizedBox(height: 32),

                    const TalkToMaya(),
                    const SizedBox(height: 16),
                    ToDoList(
                      todos: todos,
                      isLoading: isLoadingTodos,
                      onAdd: fetchToDos,
                      onUpdate: fetchToDos,
                      onDelete: fetchToDos,
                    ),
                    const SizedBox(height: 16),
                    const FeaturesSection(),
                    const SizedBox(height: 32),
                    const GoRouterDemo(),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: sendNotification,
                        child: const Text("Send Test Notification"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FCM Token',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            fcmToken == null
                                ? const Text('Loading token...')
                                : SelectableText(
                                    fcmToken!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: fcmToken == null
                                    ? null
                                    : copyFcmToken,
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy Token'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ✅ Display Location Permission Status
                            const Text(
                              'Location Permission Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              locationPermissionStatus ??
                                  'Checking permission...',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    locationPermissionStatus?.contains(
                                          'granted',
                                        ) ??
                                        false
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
