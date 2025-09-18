import 'package:flutter_contacts/flutter_contacts.dart'; // New import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_flutter_app/core/services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsService {
  static const String _contactsPermissionKey = 'contacts_permission_granted';

  /// Requests permission to access contacts and returns true if granted.
  static Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    final storage = await _getStorageService();
    if (status.isGranted) {
      await storage.setBool(_contactsPermissionKey, true);
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    await storage.setBool(_contactsPermissionKey, false);
    return false;
  }

  /// Checks if contacts permission is already granted (cached).
  static Future<bool> hasContactsPermission() async {
    final storage = await _getStorageService();
    return await storage.getBool(_contactsPermissionKey) ?? false;
  }

  /// Fetches contacts as List<Map<String, String>> for your API payload.
  static Future<List<Map<String, String>>> fetchContacts() async {
    // Use flutter_contacts to fetch with phone properties
    final List<Contact> contacts = await FlutterContacts.getContacts(
      withProperties: true,  // Required to include phones/emails
      withPhoto: false,      // Skip photos to save time/bandwidth
    );
    return contacts
        .where((contact) => contact.phones.isNotEmpty)
        .map((contact) => {
              'name': contact.displayName ?? '',
              'phone': contact.phones.first.number ?? '',
              // Add more if needed: 'email': contact.emails.firstOrNull?.address ?? '',
            })
        .toList();
  }

  // Static field (nullable to allow lazy async init)
  static StorageService? _storageService;

  // Helper to get StorageService instance (async init if needed)
  static Future<StorageService> _getStorageService() async {
    _storageService ??= await _initStorageService();
    return _storageService!;
  }

  // Private async initializer for StorageService
  static Future<StorageService> _initStorageService() async {
    final secureStorage = const FlutterSecureStorage();
    final preferences = await SharedPreferences.getInstance();
    return StorageServiceImpl(secureStorage, preferences);
  }
}