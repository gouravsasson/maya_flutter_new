// core/services/profile_sync_service.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:Maya/core/services/notification_service.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:get_it/get_it.dart';

class ProfileSyncService {
  final NotificationServices _notif = NotificationServices();
  final ApiClient _api = GetIt.I<ApiClient>();

  /// Returns a map with everything the API needs.
  /// Throws if something is permanently unavailable.
  Future<Map<String, dynamic>> gatherProfileData({
    required String firstName,
    required String lastName,
  }) async {
    // 1. FCM token
    final fcmToken = await _notif.getDeviceToken();
    if (fcmToken == null) throw Exception('FCM token unavailable');

    // 2. Location + timezone
    final location = await _getLocationWithTimezone();

    return {
      'firstName': firstName,
      'lastName': lastName,
      'fcmToken': fcmToken,
      'latitude': location['latitude'],
      'longitude': location['longitude'],
      'timezone': location['timezone'],
    };
  }

  /// Returns {latitude, longitude, timezone}
  Future<Map<String, dynamic>> _getLocationWithTimezone() async {
    // ---- permission & service check (reuse your existing logic) ----
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location service disabled');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) throw Exception('Location denied');
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permanently denied');
    }

    // ---- position ----
    final Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ---- timezone (flutter_timezone) ----
    String tz;
    try {
      tz = (await FlutterTimezone.getLocalTimezone()) as String;
    } catch (_) {
      // Fallback #1 – use the offset from the device
      final offset = DateTime.now().timeZoneOffset;
      tz = 'UTC${offset.isNegative ? '' : '+'}${offset.inHours}';
      debugPrint('flutter_timezone failed → using offset fallback: $tz');
    }

    // Fallback #2 – if still empty, use UTC (very rare)
    tz = tz.isEmpty ? 'UTC' : tz;

    return {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timezone': tz,
    };
  }

  /// Call the API
  Future<Map<String, dynamic>> syncProfile({
    required String firstName,
    required String lastName,
  }) async {
    final data = await gatherProfileData(
      firstName: firstName,
      lastName: lastName,
    );

    return _api.updateUserProfile(
      firstName: data['firstName'],
      lastName: data['lastName'],
      fcmToken: data['fcmToken'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      timezone: data['timezone'],
    );
  }
}