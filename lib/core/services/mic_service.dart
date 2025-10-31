import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class MicrophonePermissionHandler {
  /// Request microphone permission with proper state handling
  static Future<bool> requestPermission() async {
    // First check current status
    final status = await Permission.microphone.status;
    
    // If already granted, return true
    if (status.isGranted) {
      return true;
    }
    
    // If permanently denied, open settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    // Request permission
    final result = await Permission.microphone.request();
    
    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Check if microphone permission is already granted
  static Future<bool> isGranted() async {
    return await Permission.microphone.isGranted;
  }

  /// Get current permission status
  static Future<PermissionStatus> getStatus() async {
    return await Permission.microphone.status;
  }

  /// Show permission dialog with context
  static Future<bool> requestPermissionWithDialog(BuildContext context) async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return await _showPermissionDialog(
        context,
        permanent: true,
      );
    }
    
    // Show rationale dialog before requesting
    final shouldRequest = await _showPermissionDialog(context);
    
    if (!shouldRequest) {
      return false;
    }
    
    final result = await Permission.microphone.request();
    
    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      await _showPermissionDialog(context, permanent: true);
      return false;
    }
    
    return false;
  }

  static Future<bool> _showPermissionDialog(
    BuildContext context, {
    bool permanent = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: !permanent,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mic,
                color: permanent ? Colors.red : Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Microphone Access'),
            ],
          ),
          content: Text(
            permanent
                ? 'Microphone permission is permanently denied. Please enable it in app settings to use voice features.'
                : 'Maya needs microphone access to have voice conversations with you. This allows real-time speech recognition and interaction.',
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            if (!permanent)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                if (permanent) {
                  openAppSettings();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: permanent ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(permanent ? 'Open Settings' : 'Grant Permission'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}