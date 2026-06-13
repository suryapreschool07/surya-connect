import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../models/models.dart';
import '../storage/hive_storage.dart';
import '../sync/sync_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final hiveStorageProvider = Provider<HiveStorage>((ref) => HiveStorage());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider), ref.watch(hiveStorageProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(apiClientProvider),
    ref.watch(hiveStorageProvider),
    ref.watch(authServiceProvider),
  );
});

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  return DataRepository(ref.watch(syncServiceProvider));
});

final syncDataProvider =
    StateNotifierProvider<SyncDataNotifier, AsyncValue<SyncDataState>>(
  (ref) => SyncDataNotifier(ref),
);

class SyncDataState {
  SyncDataState({this.data, this.isRefreshing = false, this.error});

  final SyncData? data;
  final bool isRefreshing;
  final String? error;

  SyncDataState copyWith({
    SyncData? data,
    bool? isRefreshing,
    String? error,
  }) {
    return SyncDataState(
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

class SyncDataNotifier extends StateNotifier<AsyncValue<SyncDataState>> {
  SyncDataNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    final cached = _ref.read(syncServiceProvider).cached;
    if (cached != null) {
      state = AsyncValue.data(SyncDataState(data: cached));
    }
    await refresh(silent: cached != null);
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = AsyncValue.data(
        (state.value ?? SyncDataState()).copyWith(isRefreshing: true, error: null),
      );
    }
    try {
      final data = await _ref.read(syncServiceProvider).syncFromServer();
      state = AsyncValue.data(SyncDataState(data: data));
    } catch (e) {
      final cached = _ref.read(syncServiceProvider).cached;
      state = AsyncValue.data(
        SyncDataState(
          data: cached,
          error: '$e',
          isRefreshing: false,
        ),
      );
    }
  }
}
