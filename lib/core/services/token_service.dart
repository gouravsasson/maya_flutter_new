import 'package:jwt_decoder/jwt_decoder.dart';
import 'storage_service.dart';

class TokenService {
  final StorageService _storageService;
  
  TokenService(this._storageService);
  
  Future<bool> isTokenValid() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return false;
    
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> isRefreshTokenValid() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      return !JwtDecoder.isExpired(refreshToken);
    } catch (e) {
      return false;
    }
  }
  
  Future<DateTime?> getTokenExpiryDate() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return null;
    
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getTokenPayload() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return null;
    
    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }
}