import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

abstract class StorageService {
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> saveUserData(String userData);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserData();
  Future<void> clearAll();
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);

}

class StorageServiceImpl implements StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;
  
  StorageServiceImpl(this._secureStorage, this._preferences);
  
  @override
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: token);
  }
  
  @override
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: token);
  }
  
  @override
  Future<void> saveUserData(String userData) async {
    await _preferences.setString(AppConstants.userDataKey, userData);
  }
  
  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }
  
  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }
  
  @override
  Future<String?> getUserData() async {
    return _preferences.getString(AppConstants.userDataKey);
  }
  
  @override
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _preferences.remove(AppConstants.userDataKey);
  }
  @override
  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _preferences.getBool(key);
  }
}