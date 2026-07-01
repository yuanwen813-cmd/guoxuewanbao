import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/local_persistence/local_json_store.dart';
import 'natal_profile_models.dart';

final birthProfileStoreProvider =
    StateNotifierProvider<BirthProfileStore, List<BirthProfile>>(
  (ref) => BirthProfileStore(),
);

class BirthProfileStore extends StateNotifier<List<BirthProfile>> {
  BirthProfileStore() : super(const []) {
    _load();
  }

  static const _storageKey = 'guoxueapp.birth_profiles.v1';

  void save(BirthProfile profile) {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    state = [
      updated,
      ...state.where((item) => item.id != profile.id),
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    _persist();
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

  Future<void> _load() async {
    try {
      final raw = await readLocalJson(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .map((item) => BirthProfile.fromJson(item as Map<String, dynamic>))
          .toList();
      if (loaded.isEmpty) return;
      final currentIds = state.map((item) => item.id).toSet();
      state = [
        ...state,
        ...loaded.where((item) => !currentIds.contains(item.id)),
      ];
    } catch (_) {
      // Corrupt local data should not block the app. The user can continue and
      // newly saved profiles will rewrite the local snapshot.
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
    await writeLocalJson(_storageKey, encoded);
  }
}
