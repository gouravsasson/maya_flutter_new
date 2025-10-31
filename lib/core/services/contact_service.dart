import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsService {
  // ------------------------------------------------------------
  // 1. Permission flow (simplified - no caching needed)
  // ------------------------------------------------------------
  static Future<bool> _ensurePermission() async {
    final status = await Permission.contacts.status;
    
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    final result = await Permission.contacts.request();
    return result.isGranted;
  }

  static Future<bool> hasPermission() async {
    return (await Permission.contacts.status).isGranted;
  }

  // ------------------------------------------------------------
  // 2. Safe contacts fetch
  // ------------------------------------------------------------
  static Future<List<Map<String, String>>?> fetchContactsSafely() async {
    final granted = await _ensurePermission();
    if (!granted) return null;

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
      print('Unexpected contacts error: $e');
      return null;
    }
  }
}