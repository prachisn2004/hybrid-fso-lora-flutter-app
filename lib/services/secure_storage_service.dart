import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Single initialized instance of secure key-value hardware storage
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Storage tracking keys
  static const String _tokenKey = 'user_token';
  static const String _keyTargetNode = 'assigned_node_id';

  /// Save the token when login is successful
  static Future<void> saveUserToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve the token on app startup
  static Future<String?> getUserToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete token when logging out
  static Future<void> deleteUserToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Assign a hardware target transceiver Node ID
  static Future<void> assignNode(String nodeId) async {
    await _storage.write(key: _keyTargetNode, value: nodeId);
  }

  /// Retrieve the saved hardware Node ID
  static Future<String?> getAssignedNode() async {
    return await _storage.read(key: _keyTargetNode);
  }

  /// Delete a specific record (e.g., clearing hardware assignment)
  static Future<void> removeNodeAssignment() async {
    await _storage.delete(key: _keyTargetNode);
  }

  /// Clear everything (Crucial for User Logouts or Terminal Shutdowns)
  static Future<void> clearEntireVault() async {
    await _storage.deleteAll();
  }
}
