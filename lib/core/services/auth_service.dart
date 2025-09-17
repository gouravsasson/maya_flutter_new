import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'storage_service.dart';
import 'navigation_service.dart';
import '../../injection_container.dart';

class AuthService {
  final StorageService _storageService = sl<StorageService>();
  Timer? _tokenExpiryTimer;
  Timer? _refreshTimer;
  
  void startTokenManagement() {
    print('🔑 Starting token management...');
    _startTokenExpiryCheck();
    _startPeriodicTokenRefresh();
  }
  
  void stopTokenManagement() {
    print('🔑 Stopping token management...');
    _tokenExpiryTimer?.cancel();
    _refreshTimer?.cancel();
  }
  
  void _startTokenExpiryCheck() {
    _tokenExpiryTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        if (JwtDecoder.isExpired(token)) {
          await _handleTokenExpiry();
        }
      }
    });
  }
  
  void _startPeriodicTokenRefresh() {
    _refreshTimer = Timer.periodic(Duration(minutes: 10), (timer) async {
      await _attemptTokenRefresh();
    });
  }
  
  Future<void> _handleTokenExpiry() async {
    print('🔑 Token expired, attempting refresh...');
    
    final refreshed = await _attemptTokenRefresh();
    if (!refreshed) {
      print('❌ Token refresh failed, performing auto logout...');
      await _performAutoLogout();
    }
  }
  
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || JwtDecoder.isExpired(refreshToken)) {
        return false;
      }
      
      print('🔄 Refreshing token...');
      
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      
      // For demo, generate a new mock token
      final newToken = _generateMockToken();
      await _storageService.saveAccessToken(newToken);
      
      print('✅ Token refreshed successfully');
      return true;
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    }
  }
  
  Future<void> _performAutoLogout() async {
    print('🚪 Performing auto logout...');
    
    // Clear all stored data
    await _storageService.clearAll();
    
    // Stop token management
    stopTokenManagement();
    
    // Navigate to login and show dialog
    final currentContext = NavigationService.navigatorKey.currentContext;
    if (currentContext != null) {
      // Navigate to login first
      currentContext.go('/login');
      
      // Then show the dialog
      await Future.delayed(Duration(milliseconds: 100));
      NavigationService.showSessionExpiredDialog();
    }
  }
  
  String _generateMockToken() {
    final exp = DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0Ijo${DateTime.now().millisecondsSinceEpoch ~/ 1000},"exp":$exp}.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
  }
}