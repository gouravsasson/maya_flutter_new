import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';   // your StorageService

class ContactsService {
  static const _permissionKey = 'contacts_permission_granted';
  static StorageService? _storage;

  // ------------------------------------------------------------
  // 1. Permission flow
  // ------------------------------------------------------------
  static Future<bool> _ensurePermission() async {
    final status = await Permission.contacts.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final result = await Permission.contacts.request();
    final granted = result.isGranted;

    // cache the result for the next app start
    final storage = await _getStorage();
    await storage.setBool(_permissionKey, granted);
    return granted;
  }

  static Future<bool> hasPermission() async {
    final storage = await _getStorage();
    final cached = await storage.getBool(_permissionKey) ?? false;
    if (!cached) return false;

    // double-check the OS (cached value could be stale)
    return (await Permission.contacts.status).isGranted;
  }

  // ------------------------------------------------------------
  // 2. Safe contacts fetch
  // ------------------------------------------------------------
  static Future<List<Map<String, String>>?> fetchContactsSafely() async {
    final granted = await _ensurePermission();
    if (!granted) return null;               // caller must handle denial

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      return contacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => {
                'name': c.displayName ?? '',
                'phone': c.phones.first.number ?? '',
              })
          .toList();
    } on Exception catch (e) {
      // This should never happen if permission was granted,
      // but we guard anyway.
      print('Unexpected contacts error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------
  // 3. Storage helper (lazy init)
  // ------------------------------------------------------------
  static Future<StorageService> _getStorage() async {
    _storage ??= await _initStorage();
    return _storage!;
  }

  static Future<StorageService> _initStorage() async {
    final secure = const FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    return StorageServiceImpl(secure, prefs);
  }
}