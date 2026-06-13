import 'package:hive_flutter/hive_flutter.dart';

import '../../app/constants.dart';
import '../models/models.dart';

class HiveStorage {
  Box<dynamic>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(AppConstants.hiveBoxName);
  }

  Box<dynamic> get box {
    final b = _box;
    if (b == null) throw StateError('HiveStorage not initialized');
    return b;
  }

  Future<void> saveSyncData(SyncData data) async {
    await box.put('sync_data', data.toJson());
    await box.put('sync_at', DateTime.now().toIso8601String());
  }

  SyncData? loadSyncData() {
    final raw = box.get('sync_data');
    if (raw is! Map) return null;
    return SyncData.fromJson(Map<String, dynamic>.from(raw));
  }

  DateTime? lastSyncAt() {
    final raw = box.get('sync_at');
    if (raw == null) return null;
    return DateTime.tryParse('$raw');
  }

  Future<void> clear() async {
    await box.clear();
  }
}
