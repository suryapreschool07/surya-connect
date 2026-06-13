import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../storage/hive_storage.dart';

enum UserRole { admin, parent, none }

class AuthSession {
  AuthSession({
    required this.role,
    this.token = '',
    this.phone = '',
    this.linkedStudentIds = const [],
    this.selectedStudentId = '',
  });

  final UserRole role;
  final String token;
  final String phone;
  final List<String> linkedStudentIds;
  final String selectedStudentId;

  bool get isAuthenticated => role != UserRole.none && token.isNotEmpty;
}

class AuthService {
  AuthService(this._api, this._storage);

  final ApiClient _api;
  final HiveStorage _storage;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<AuthSession> loadSession() async {
    final p = await prefs;
    final roleStr = p.getString(AppConstants.prefsRoleKey);
    final token = p.getString(AppConstants.prefsTokenKey) ?? '';
    final phone = p.getString(AppConstants.prefsPhoneKey) ?? '';
    final studentIds = p.getStringList(AppConstants.prefsStudentIdsKey) ?? [];
    final selected = p.getString(AppConstants.prefsSelectedStudentKey) ?? '';

    UserRole role = UserRole.none;
    if (roleStr == 'admin') role = UserRole.admin;
    if (roleStr == 'parent') role = UserRole.parent;

    return AuthSession(
      role: role,
      token: token,
      phone: phone,
      linkedStudentIds: studentIds,
      selectedStudentId: selected.isNotEmpty
          ? selected
          : (studentIds.isNotEmpty ? studentIds.first : ''),
    );
  }

  Future<AuthSession> loginAdmin(String password) async {
    final result = await _api.adminLogin(password);
    final data = _extractData(result);
    final token = '${data['token']}';
    await _persist(
      role: UserRole.admin,
      token: token,
      phone: '',
      studentIds: [],
      selectedStudentId: '',
    );
    return AuthSession(role: UserRole.admin, token: token);
  }

  Future<AuthSession> loginParent(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'\D'), '');
    final result = await _api.parentLogin(normalized);
    final data = _extractData(result);
    final token = '${data['token']}';
    final ids = (data['studentIds'] as List?)?.map((e) => '$e').toList() ?? [];
    if (ids.isEmpty) {
      throw ApiException('No student linked to this phone number');
    }
    await _persist(
      role: UserRole.parent,
      token: token,
      phone: normalized,
      studentIds: ids,
      selectedStudentId: ids.first,
    );
    return AuthSession(
      role: UserRole.parent,
      token: token,
      phone: normalized,
      linkedStudentIds: ids,
      selectedStudentId: ids.first,
    );
  }

  Future<void> setSelectedStudent(String studentId) async {
    final p = await prefs;
    await p.setString(AppConstants.prefsSelectedStudentKey, studentId);
  }

  Future<void> logout() async {
    final p = await prefs;
    await p.remove(AppConstants.prefsTokenKey);
    await p.remove(AppConstants.prefsRoleKey);
    await p.remove(AppConstants.prefsPhoneKey);
    await p.remove(AppConstants.prefsStudentIdsKey);
    await p.remove(AppConstants.prefsSelectedStudentKey);
    await _storage.clear();
  }

  Future<void> _persist({
    required UserRole role,
    required String token,
    required String phone,
    required List<String> studentIds,
    required String selectedStudentId,
  }) async {
    final p = await prefs;
    await p.setString(AppConstants.prefsTokenKey, token);
    await p.setString(
      AppConstants.prefsRoleKey,
      role == UserRole.admin ? 'admin' : 'parent',
    );
    await p.setString(AppConstants.prefsPhoneKey, phone);
    await p.setStringList(AppConstants.prefsStudentIdsKey, studentIds);
    await p.setString(AppConstants.prefsSelectedStudentKey, selectedStudentId);
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return result;
  }
}
