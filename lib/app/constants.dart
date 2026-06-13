/// App-wide constants. Update [apiBaseUrl] after deploying Google Apps Script.
class AppConstants {
  AppConstants._();

  static const String appName = 'Surya Connect';
  static const String schoolName = 'Surya Pre-School';
  static const String schoolPhone = '7862021425';
  static const String schoolEmail = 'suryapreschool07@gmail.com';

  /// Deploy Apps Script as Web App, then paste URL here (no trailing slash).
  static const String apiBaseUrl =
      'https://script.google.com/macros/s/AKfycbz6Hb0icLDPK3tG7qGiMYAepVvr9-Ccm2zKLoMUTSqFDRhUll5O0hb_d4QLVu4rCkD7hg/exec';

  static const String hiveBoxName = 'surya_connect_cache';
  static const String prefsTokenKey = 'auth_token';
  static const String prefsRoleKey = 'auth_role';
  static const String prefsPhoneKey = 'auth_phone';
  static const String prefsStudentIdsKey = 'linked_student_ids';
  static const String prefsSelectedStudentKey = 'selected_student_id';
}
