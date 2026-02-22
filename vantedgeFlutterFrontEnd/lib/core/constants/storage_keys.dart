/// Storage keys for the banking application.
///
/// This file contains all keys used for local storage, including
/// keys for tokens, user data, preferences, and other cached data.
///
/// These keys are used with shared preferences, secure storage,
/// or other local storage mechanisms to persist data across app sessions.
class StorageKeys {
  // Prevent instantiation
  StorageKeys._();

  // ==================== Authentication Keys ====================

  /// Key for storing the access token (JWT)
  /// Type: String
  /// Storage: Secure Storage (encrypted)
  static const String accessToken = 'access_token';

  /// Key for storing the refresh token
  /// Type: String
  /// Storage: Secure Storage (encrypted)
  static const String refreshToken = 'refresh_token';

  /// Key for storing token expiry timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Secure Storage
  static const String tokenExpiry = 'token_expiry';

  /// Key for storing authentication status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String isAuthenticated = 'is_authenticated';

  /// Key for storing last authentication timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String lastAuthTimestamp = 'last_auth_timestamp';

  // ==================== User Data Keys ====================

  /// Key for storing user ID
  /// Type: int
  /// Storage: Shared Preferences
  static const String userId = 'user_id';

  /// Key for storing username
  /// Type: String
  /// Storage: Shared Preferences
  static const String username = 'username';

  /// Key for storing user email
  /// Type: String
  /// Storage: Shared Preferences
  static const String userEmail = 'user_email';

  /// Key for storing user full name
  /// Type: String
  /// Storage: Shared Preferences
  static const String userFullName = 'user_full_name';

  /// Key for storing user first name
  /// Type: String
  /// Storage: Shared Preferences
  static const String userFirstName = 'user_first_name';

  /// Key for storing user last name
  /// Type: String
  /// Storage: Shared Preferences
  static const String userLastName = 'user_last_name';

  /// Key for storing user phone number
  /// Type: String
  /// Storage: Shared Preferences
  static const String userPhone = 'user_phone';

  /// Key for storing user role
  /// Type: String (e.g., CUSTOMER, ADMIN, etc.)
  /// Storage: Shared Preferences
  static const String userRole = 'user_role';

  /// Key for storing user status
  /// Type: String (PENDING, ACTIVE, INACTIVE)
  /// Storage: Shared Preferences
  static const String userStatus = 'user_status';

  /// Key for storing user profile picture URL
  /// Type: String (URL)
  /// Storage: Shared Preferences
  static const String userProfilePicture = 'user_profile_picture';

  /// Key for storing user date of birth
  /// Type: String (ISO 8601 format)
  /// Storage: Shared Preferences
  static const String userDateOfBirth = 'user_date_of_birth';

  /// Key for storing user address
  /// Type: String (JSON)
  /// Storage: Shared Preferences
  static const String userAddress = 'user_address';

  /// Key for storing complete user data as JSON
  /// Type: String (JSON)
  /// Storage: Shared Preferences
  static const String userData = 'user_data';

  // ==================== Account Data Keys ====================

  /// Key for storing primary account ID
  /// Type: int
  /// Storage: Shared Preferences
  static const String primaryAccountId = 'primary_account_id';

  /// Key for storing primary account number
  /// Type: String
  /// Storage: Shared Preferences
  static const String primaryAccountNumber = 'primary_account_number';

  /// Key for storing list of user accounts (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String userAccounts = 'user_accounts';

  /// Key for storing selected account ID
  /// Type: int
  /// Storage: Shared Preferences
  static const String selectedAccountId = 'selected_account_id';

  /// Key for storing cached account balance
  /// Type: double
  /// Storage: Shared Preferences
  static const String cachedAccountBalance = 'cached_account_balance';

  /// Key for storing last balance update timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String lastBalanceUpdate = 'last_balance_update';

  // ==================== App Preferences Keys ====================

  /// Key for storing theme mode preference
  /// Type: String (light, dark, system)
  /// Storage: Shared Preferences
  static const String themeMode = 'theme_mode';

  /// Key for storing language preference
  /// Type: String (language code, e.g., en, es, fr)
  /// Storage: Shared Preferences
  static const String languageCode = 'language_code';

  /// Key for storing notification enabled preference
  /// Type: bool
  /// Storage: Shared Preferences
  static const String notificationsEnabled = 'notifications_enabled';

  /// Key for storing biometric authentication preference
  /// Type: bool
  /// Storage: Shared Preferences
  static const String biometricEnabled = 'biometric_enabled';

  /// Key for storing face ID enabled preference
  /// Type: bool
  /// Storage: Shared Preferences
  static const String faceIdEnabled = 'face_id_enabled';

  /// Key for storing fingerprint enabled preference
  /// Type: bool
  /// Storage: Shared Preferences
  static const String fingerprintEnabled = 'fingerprint_enabled';

  /// Key for storing auto-lock timeout preference
  /// Type: int (minutes)
  /// Storage: Shared Preferences
  static const String autoLockTimeout = 'auto_lock_timeout';

  /// Key for storing currency display preference
  /// Type: String (USD, EUR, GBP, etc.)
  /// Storage: Shared Preferences
  static const String currencyPreference = 'currency_preference';

  /// Key for storing date format preference
  /// Type: String (MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD)
  /// Storage: Shared Preferences
  static const String dateFormatPreference = 'date_format_preference';

  // ==================== Onboarding & First Launch Keys ====================

  /// Key for storing onboarding completed status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String onboardingCompleted = 'onboarding_completed';

  /// Key for storing first launch status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String isFirstLaunch = 'is_first_launch';

  /// Key for storing app version at first launch
  /// Type: String
  /// Storage: Shared Preferences
  static const String firstLaunchVersion = 'first_launch_version';

  /// Key for storing current app version
  /// Type: String
  /// Storage: Shared Preferences
  static const String currentAppVersion = 'current_app_version';

  /// Key for storing terms acceptance status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String termsAccepted = 'terms_accepted';

  /// Key for storing privacy policy acceptance status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String privacyPolicyAccepted = 'privacy_policy_accepted';

  // ==================== Session Management Keys ====================

  /// Key for storing session ID
  /// Type: String
  /// Storage: Shared Preferences
  static const String sessionId = 'session_id';

  /// Key for storing session start timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String sessionStartTime = 'session_start_time';

  /// Key for storing last activity timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String lastActivityTime = 'last_activity_time';

  /// Key for storing remember me preference
  /// Type: bool
  /// Storage: Shared Preferences
  static const String rememberMe = 'remember_me';

  /// Key for storing saved username (if remember me is enabled)
  /// Type: String
  /// Storage: Shared Preferences
  static const String savedUsername = 'saved_username';

  // ==================== Cache Keys ====================

  /// Key for storing cached transactions (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String cachedTransactions = 'cached_transactions';

  /// Key for storing cached loans (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String cachedLoans = 'cached_loans';

  /// Key for storing cached cards (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String cachedCards = 'cached_cards';

  /// Key for storing cached branches (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String cachedBranches = 'cached_branches';

  /// Key for storing last cache update timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String lastCacheUpdate = 'last_cache_update';

  /// Key for storing cache expiry duration in milliseconds
  /// Type: int (milliseconds)
  /// Storage: Shared Preferences
  static const String cacheExpiryDuration = 'cache_expiry_duration';

  // ==================== Security Keys ====================

  /// Key for storing PIN code (hashed)
  /// Type: String (hashed PIN)
  /// Storage: Secure Storage (encrypted)
  static const String pinCode = 'pin_code';

  /// Key for storing PIN enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String pinEnabled = 'pin_enabled';

  /// Key for storing failed login attempts count
  /// Type: int
  /// Storage: Shared Preferences
  static const String failedLoginAttempts = 'failed_login_attempts';

  /// Key for storing account locked status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String accountLocked = 'account_locked';

  /// Key for storing account lock timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String accountLockTime = 'account_lock_time';

  /// Key for storing last password change timestamp
  /// Type: int (milliseconds since epoch)
  /// Storage: Shared Preferences
  static const String lastPasswordChange = 'last_password_change';

  // ==================== Feature Flags & Settings Keys ====================

  /// Key for storing quick transfer enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String quickTransferEnabled = 'quick_transfer_enabled';

  /// Key for storing transaction notifications enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String transactionNotificationsEnabled =
      'transaction_notifications_enabled';

  /// Key for storing marketing notifications enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String marketingNotificationsEnabled =
      'marketing_notifications_enabled';

  /// Key for storing security alerts enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String securityAlertsEnabled = 'security_alerts_enabled';

  /// Key for storing dark mode preference
  /// Type: bool
  /// Storage: Shared Preferences
  static const String darkModeEnabled = 'dark_mode_enabled';

  /// Key for storing haptic feedback enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String hapticFeedbackEnabled = 'haptic_feedback_enabled';

  /// Key for storing sound effects enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String soundEffectsEnabled = 'sound_effects_enabled';

  // ==================== Analytics & Tracking Keys ====================

  /// Key for storing analytics enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String analyticsEnabled = 'analytics_enabled';

  /// Key for storing crash reporting enabled status
  /// Type: bool
  /// Storage: Shared Preferences
  static const String crashReportingEnabled = 'crash_reporting_enabled';

  /// Key for storing user ID for analytics
  /// Type: String
  /// Storage: Shared Preferences
  static const String analyticsUserId = 'analytics_user_id';

  /// Key for storing device ID
  /// Type: String
  /// Storage: Shared Preferences
  static const String deviceId = 'device_id';

  /// Key for storing FCM token (Firebase Cloud Messaging)
  /// Type: String
  /// Storage: Shared Preferences
  static const String fcmToken = 'fcm_token';

  // ==================== Quick Actions & Favorites Keys ====================

  /// Key for storing favorite accounts (JSON)
  /// Type: String (JSON array of account IDs)
  /// Storage: Shared Preferences
  static const String favoriteAccounts = 'favorite_accounts';

  /// Key for storing recent beneficiaries (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String recentBeneficiaries = 'recent_beneficiaries';

  /// Key for storing saved beneficiaries (JSON)
  /// Type: String (JSON array)
  /// Storage: Shared Preferences
  static const String savedBeneficiaries = 'saved_beneficiaries';

  /// Key for storing quick transfer amount presets (JSON)
  /// Type: String (JSON array of amounts)
  /// Storage: Shared Preferences
  static const String quickTransferPresets = 'quick_transfer_presets';

  // ==================== Helper Methods ====================

  /// Gets a list of all authentication-related keys
  static List<String> getAuthKeys() {
    return [
      accessToken,
      refreshToken,
      tokenExpiry,
      isAuthenticated,
      lastAuthTimestamp,
    ];
  }

  /// Gets a list of all user data keys
  static List<String> getUserDataKeys() {
    return [
      userId,
      username,
      userEmail,
      userFullName,
      userFirstName,
      userLastName,
      userPhone,
      userRole,
      userStatus,
      userProfilePicture,
      userDateOfBirth,
      userAddress,
      userData,
    ];
  }

  /// Gets a list of all secure storage keys (sensitive data)
  static List<String> getSecureStorageKeys() {
    return [
      accessToken,
      refreshToken,
      tokenExpiry,
      pinCode,
    ];
  }

  /// Gets a list of all cache keys
  static List<String> getCacheKeys() {
    return [
      cachedTransactions,
      cachedLoans,
      cachedCards,
      cachedBranches,
      cachedAccountBalance,
      lastCacheUpdate,
      lastBalanceUpdate,
    ];
  }

  /// Gets a list of all preference keys
  static List<String> getPreferenceKeys() {
    return [
      themeMode,
      languageCode,
      notificationsEnabled,
      biometricEnabled,
      faceIdEnabled,
      fingerprintEnabled,
      autoLockTimeout,
      currencyPreference,
      dateFormatPreference,
      darkModeEnabled,
      hapticFeedbackEnabled,
      soundEffectsEnabled,
    ];
  }

  /// Gets a list of keys to clear on logout
  static List<String> getLogoutClearKeys() {
    return [
      accessToken,
      refreshToken,
      tokenExpiry,
      isAuthenticated,
      sessionId,
      sessionStartTime,
      lastActivityTime,
      userData,
      userAccounts,
      cachedTransactions,
      cachedLoans,
      cachedCards,
      cachedAccountBalance,
      primaryAccountId,
      primaryAccountNumber,
      selectedAccountId,
    ];
  }

  /// Gets a list of keys to keep on logout (user preferences)
  static List<String> getKeepOnLogoutKeys() {
    return [
      rememberMe,
      savedUsername,
      themeMode,
      languageCode,
      onboardingCompleted,
      termsAccepted,
      privacyPolicyAccepted,
      currencyPreference,
      dateFormatPreference,
    ];
  }
}
