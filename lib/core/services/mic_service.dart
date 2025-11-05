import 'package:permission_handler/permission_handler.dart';

class MicrophonePermissionHandler {
  /// Request microphone permission
  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // Open app settings if permanently denied
      await openAppSettings();
      return false;
    }
    return false;
  }

  /// Check if microphone permission is already granted
  static Future<bool> isGranted() async {
    return await Permission.microphone.isGranted;
  }
}
