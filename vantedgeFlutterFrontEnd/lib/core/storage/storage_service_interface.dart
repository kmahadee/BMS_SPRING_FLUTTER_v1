abstract class IStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  
  Future<void> saveTokenExpiry(int timestamp);
  Future<int?> getTokenExpiry();
  
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
  
  Future<void> saveUserRole(String role);
  Future<String?> getUserRole();
  
  Future<void> saveUserId(int id);
  Future<int?> getUserId();
  
  Future<void> saveUsername(String username);
  Future<String?> getUsername();
  
  Future<void> savePinCode(String hashedPin);
  Future<String?> getPinCode();
  
  Future<void> saveIsAuthenticated(bool isAuthenticated);
  Future<bool> getIsAuthenticated();
  
  Future<void> saveRememberMe(bool rememberMe);
  Future<bool> getRememberMe();
  
  Future<void> saveSavedUsername(String username);
  Future<String?> getSavedUsername();
  
  Future<void> clearAll();
  Future<void> clearAuthData();
  Future<void> clearUserData();
  
  Future<bool> hasValidToken();
  Future<bool> isTokenExpired();
}