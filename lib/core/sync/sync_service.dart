import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../models/models.dart';
import '../storage/hive_storage.dart';

class SyncService {
  SyncService(this._api, this._storage, this._auth);

  final ApiClient _api;
  final HiveStorage _storage;
  final AuthService _auth;

  SyncData? get cached => _storage.loadSyncData();

  Future<SyncData> syncFromServer() async {
    final session = await _auth.loadSession();
    if (!session.isAuthenticated) {
      throw ApiException('Not authenticated');
    }

    final role = session.role == UserRole.admin ? 'admin' : 'parent';
    final data = await _api.sync(
      role: role,
      token: session.token,
      phone: session.phone.isNotEmpty ? session.phone : null,
    );
    await _storage.saveSyncData(data);
    return data;
  }

  Future<SyncData> syncOrCache() async {
    try {
      return await syncFromServer();
    } catch (_) {
      final cached = _storage.loadSyncData();
      if (cached != null) return cached;
      rethrow;
    }
  }
}

class DataRepository {
  DataRepository(this._sync);

  final SyncService _sync;

  SyncData get data => _sync.cached ?? SyncData();

  Future<SyncData> refresh() => _sync.syncFromServer();

  StudentModel? studentById(String id) {
    try {
      return data.students.firstWhere((s) => s.studentId == id);
    } catch (_) {
      return null;
    }
  }

  List<StudentModel> studentsInClass(String classId) {
    return data.students
        .where((s) => s.classId == classId && s.active)
        .toList();
  }

  int totalPaidForStudent(String studentId) {
    return data.feePayments
        .where((p) => p.studentId == studentId)
        .fold<int>(0, (sum, p) => sum + p.amountPaid);
  }

  int pendingFeesForStudent(String studentId) {
    final student = studentById(studentId);
    if (student == null) return 0;
    return student.totalFees - totalPaidForStudent(studentId);
  }

  List<FeePaymentModel> paymentsForStudent(String studentId) {
    return data.feePayments
        .where((p) => p.studentId == studentId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  AttendanceModel? attendanceFor(String studentId, String date) {
    try {
      return data.attendance.firstWhere(
        (a) => a.studentId == studentId && a.date == date,
      );
    } catch (_) {
      return null;
    }
  }

  List<AttendanceModel> attendanceForStudent(String studentId) {
    return data.attendance.where((a) => a.studentId == studentId).toList();
  }

  double attendancePercentage(String studentId) {
    final records = attendanceForStudent(studentId)
        .where((a) => a.status == 'P' || a.status == 'A')
        .toList();
    if (records.isEmpty) return 0;
    final present = records.where((a) => a.status == 'P').length;
    return (present / records.length) * 100;
  }

  List<TestResultModel> resultsForStudent(String studentId) {
    return data.testResults.where((r) => r.studentId == studentId).toList();
  }

  TestModel? testById(String testId) {
    try {
      return data.tests.firstWhere((t) => t.testId == testId);
    } catch (_) {
      return null;
    }
  }

  int dashboardPresentToday() {
    final today = _todayKey();
    return data.attendance
        .where((a) => a.date == today && a.status == 'P')
        .length;
  }

  int dashboardAbsentToday() {
    final today = _todayKey();
    return data.attendance
        .where((a) => a.date == today && a.status == 'A')
        .length;
  }

  int totalPendingFees() {
    return data.students.fold<int>(
      0,
      (sum, s) => sum + (s.totalFees - totalPaidForStudent(s.studentId)),
    );
  }

  int totalCollectedFees() {
    return data.feePayments.fold<int>(0, (sum, p) => sum + p.amountPaid);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
