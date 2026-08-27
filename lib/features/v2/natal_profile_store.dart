import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/local_persistence/local_json_store.dart';
import '../account/user_data_api.dart';
import '../auth/auth_store.dart';
import 'natal_profile_models.dart';

final birthProfileStoreProvider =
    StateNotifierProvider<BirthProfileStore, List<BirthProfile>>(
  (ref) {
    final auth = ref.watch(authStoreProvider);
    return BirthProfileStore(
      ownerKey: HistoryOwnerKey.fromAuth(auth),
      userId: auth.user?.id,
      token: auth.token,
      cloudApi: auth.isAuthenticated ? UserDataApi() : null,
    );
  },
);

class BirthProfileStore extends StateNotifier<List<BirthProfile>> {
  BirthProfileStore({
    String ownerKey = 'guest',
    String? userId,
    String? token,
    UserDataApi? cloudApi,
  })  : _ownerKey = ownerKey,
        _userId = userId,
        _token = token,
        _cloudApi = cloudApi,
        _storageKey = ownerKey == 'guest'
            ? _legacyStorageKey
            : '$_storageKeyPrefix.$ownerKey',
        _deletedStorageKey = '$_storageKeyPrefix.$ownerKey.deleted',
        super(const []) {
    _load();
  }

  static const _legacyStorageKey = 'guoxueapp.birth_profiles.v1';
  static const _storageKeyPrefix = 'guoxueapp.birth_profiles.v2';
  final String _ownerKey;
  final String? _userId;
  final String? _token;
  final UserDataApi? _cloudApi;
  final String _storageKey;
  final String _deletedStorageKey;
  List<BirthProfile> _legacyProfiles = const [];
  final Set<String> _pendingDeletedIds = {};
  bool _syncing = false;

  bool get hasLegacyProfiles =>
      _ownerKey != 'guest' && _legacyProfiles.isNotEmpty;

  int get legacyProfileCount => _legacyProfiles.length;

  void save(BirthProfile profile) {
    final updated = profile.copyWith(
      ownerUserId: _userId ?? profile.ownerUserId,
      updatedAt: DateTime.now(),
    );
    state = [
      updated,
      ...state.where((item) => item.id != profile.id),
    ];
    _persist();
    _syncProfiles([updated]);
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    _persist();
    _syncDeleted([id]);
  }

  BirthProfile? byId(String id) {
    for (final profile in state) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  bool contains(String id) {
    return state.any((profile) => profile.id == id);
  }

  Future<void> clearLocalData() async {
    state = const [];
    _legacyProfiles = const [];
    _pendingDeletedIds.clear();
    await _persist();
    await _persistPendingDeletes();
  }

  void importLegacyProfiles() {
    if (_legacyProfiles.isEmpty) return;
    final now = DateTime.now();
    final existingIds = state.map((item) => item.id).toSet();
    final imported = _legacyProfiles
        .where((item) => !existingIds.contains(item.id))
        .map(
          (item) => item.copyWith(
            ownerUserId: _userId ?? item.ownerUserId,
            updatedAt: now,
          ),
        )
        .toList();
    state = [...imported, ...state];
    _legacyProfiles = const [];
    _persist();
    _syncProfiles(imported);
  }

  Future<void> _load() async {
    try {
      await _loadPendingDeletes();
      final raw = await readLocalJson(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded
            .map((item) => BirthProfile.fromJson(item as Map<String, dynamic>))
            .toList();
        final currentIds = state.map((item) => item.id).toSet();
        state = [
          ...state,
          ...loaded.where((item) => !currentIds.contains(item.id)),
        ];
      }
      await _loadLegacyProfiles();
      await _initialCloudSync();
    } catch (_) {
      // Corrupt local data should not block the app. The user can continue and
      // newly saved profiles will rewrite the local snapshot.
      await _initialCloudSync();
    }
  }

  Future<void> _loadLegacyProfiles() async {
    if (_ownerKey == 'guest') return;
    try {
      final raw = await readLocalJson(_legacyStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      _legacyProfiles = decoded
          .map((item) => BirthProfile.fromJson(item as Map<String, dynamic>))
          .where((item) => !state.any((current) => current.id == item.id))
          .toList();
      if (_legacyProfiles.isNotEmpty) state = [...state];
    } catch (_) {
      _legacyProfiles = const [];
    }
  }

  Future<void> _initialCloudSync() async {
    final token = _token;
    final api = _cloudApi;
    if (token == null || token.isEmpty || api == null || _syncing) return;
    _syncing = true;
    try {
      if (_pendingDeletedIds.isNotEmpty) {
        await api.sync(
          token,
          deletedProfileIds: _pendingDeletedIds.toList(),
        );
        _pendingDeletedIds.clear();
        await _persistPendingDeletes();
      }
      final snapshots = state.map((item) => item.toJson()).toList();
      var cloud = await api.fetch(token);
      for (var offset = 0; offset < snapshots.length; offset += 25) {
        final end =
            offset + 25 < snapshots.length ? offset + 25 : snapshots.length;
        cloud = await api.sync(
          token,
          profiles: snapshots.sublist(offset, end),
        );
      }
      final merged = <String, BirthProfile>{
        for (final item in state) item.id: item
      };
      for (final raw in cloud.profiles) {
        final remote = BirthProfile.fromJson(raw);
        if (_pendingDeletedIds.contains(remote.id)) continue;
        final local = merged[remote.id];
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          merged[remote.id] = remote;
        }
      }
      final values = merged.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = values;
      await _persist();
    } catch (_) {
      // 云端不可用时继续使用本地档案。
    } finally {
      _syncing = false;
    }
  }

  void _syncProfiles(List<BirthProfile> profiles) {
    final token = _token;
    final api = _cloudApi;
    if (profiles.isEmpty || token == null || token.isEmpty || api == null) {
      return;
    }
    unawaited(api
        .sync(
          token,
          profiles: profiles.map((item) => item.toJson()).toList(),
        )
        .then<void>((_) {}, onError: (_) {}));
  }

  void _syncDeleted(List<String> ids) {
    _pendingDeletedIds.addAll(ids);
    unawaited(_persistPendingDeletes());
    final token = _token;
    final api = _cloudApi;
    if (token == null || token.isEmpty || api == null) return;
    unawaited(api.sync(token, deletedProfileIds: ids).then<void>((_) {
      _pendingDeletedIds.removeAll(ids);
      return _persistPendingDeletes();
    }, onError: (_) {}));
  }

  Future<void> _loadPendingDeletes() async {
    try {
      final raw = await readLocalJson(_deletedStorageKey);
      if (raw == null || raw.isEmpty) return;
      _pendingDeletedIds.addAll((jsonDecode(raw) as List).cast<String>());
    } catch (_) {
      _pendingDeletedIds.clear();
    }
  }

  Future<void> _persistPendingDeletes() {
    return writeLocalJson(
      _deletedStorageKey,
      jsonEncode(_pendingDeletedIds.toList()),
    );
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
    await writeLocalJson(_storageKey, encoded);
  }
}

class HistoryOwnerKey {
  const HistoryOwnerKey._();

  static String fromAuth(AuthState auth) {
    final user = auth.user;
    if (!auth.isAuthenticated || user == null) return 'guest';
    final raw = user.id.isNotEmpty ? 'user_${user.id}' : 'phone_${user.phone}';
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  }
}
