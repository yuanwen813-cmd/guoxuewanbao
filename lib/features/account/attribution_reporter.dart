import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/local_persistence/local_json_store.dart';
import '../auth/auth_store.dart';
import 'attribution_platform.dart';
import 'user_data_api.dart';

class AttributionReporter extends ConsumerStatefulWidget {
  const AttributionReporter({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AttributionReporter> createState() =>
      _AttributionReporterState();
}

class _AttributionReporterState extends ConsumerState<AttributionReporter> {
  final _service = _AttributionService();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await _service.capture();
      final auth = ref.read(authStoreProvider);
      if (auth.isAuthenticated) await _service.flush(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStoreProvider, (previous, next) {
      if (next.isAuthenticated &&
          (previous?.token != next.token ||
              previous?.isAuthenticated != true)) {
        unawaited(_service.flush(next));
      }
    });
    return widget.child;
  }
}

class _AttributionService {
  static const _storageKey = 'guoxueapp.attribution.v1';
  final _api = UserDataApi();

  Future<void> capture() async {
    final query = Uri.base.queryParameters;
    final source = _firstNonBlank([
      query['utm_source'],
      query['ref'],
    ]);
    final medium = _firstNonBlank([query['utm_medium']]);
    final campaign = _firstNonBlank([query['utm_campaign'], query['feature']]);
    final referrer = attributionReferrer().trim();
    if (source == null && referrer.isEmpty) return;
    await writeLocalJson(
      _storageKey,
      jsonEncode({
        'source': source ?? 'referral',
        if (medium != null) 'medium': medium,
        if (campaign != null) 'campaign': campaign,
        if (referrer.isNotEmpty) 'referrer': referrer,
      }),
    );
  }

  Future<void> flush(AuthState auth) async {
    final token = auth.token;
    if (token == null || token.isEmpty) return;
    try {
      final raw = await readLocalJson(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      await _api.recordAttribution(
        token,
        source: data['source'] as String? ?? 'direct',
        medium: data['medium'] as String?,
        campaign: data['campaign'] as String?,
        referrer: data['referrer'] as String?,
      );
    } catch (_) {
      // 来源统计失败不影响登录与业务流程。
    }
  }

  String? _firstNonBlank(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
