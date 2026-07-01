import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../auth/auth_store.dart';
import '../wallet/server_wallet_api.dart';
import '../wallet/wallet_store.dart';
import 'ai_report_product_config.dart';

class AiReportProductPanel extends ConsumerStatefulWidget {
  final String featureKey;
  final String? sourceSummary;
  final String? sourceJson;
  final String? initialFocus;

  const AiReportProductPanel({
    super.key,
    required this.featureKey,
    this.sourceSummary,
    this.sourceJson,
    this.initialFocus,
  });

  @override
  ConsumerState<AiReportProductPanel> createState() =>
      _AiReportProductPanelState();
}

class _AiReportProductPanelState extends ConsumerState<AiReportProductPanel> {
  final _focusController = TextEditingController();
  final Map<String, String> _answers = {};
  final Map<String, String> _errors = {};
  String? _loadingProductId;

  @override
  void initState() {
    super.initState();
    _applyInitialFocus();
  }

  @override
  void didUpdateWidget(covariant AiReportProductPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFocus != widget.initialFocus &&
        _focusController.text.trim().isEmpty) {
      _applyInitialFocus();
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _applyInitialFocus() {
    final focus = widget.initialFocus?.trim();
    if (focus != null && focus.isNotEmpty) {
      _focusController.text = focus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final configs = AiReportProductCatalog.forFeature(widget.featureKey);
    if (configs.isEmpty) return const SizedBox.shrink();
    final wallet = ref.watch(walletStoreProvider);

    return Container(
      key: Key('ai_report_panel_${widget.featureKey}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: GuoXueColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI 白话解读',
                  style: GuoXueTypography.body.copyWith(
                    color: GuoXueColors.inkBlack,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '请先输入想重点了解的事项。AI 只读取当前页面已经生成的结构化结果，不重新排盘、不重新起卦。',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              letterSpacing: 0,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GuoXueColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GuoXueColors.primary.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '钱包余额：${formatWalletCents(wallet.balanceCents)}',
                    key: const Key('ai_report_wallet_balance'),
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/wallet'),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('充值'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: Key('ai_report_focus_${widget.featureKey}'),
            controller: _focusController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '想重点了解的事项',
              hintText: '例如：合作趋势、事业选择、关系相处、今年节奏',
            ),
          ),
          const SizedBox(height: 12),
          for (final config in configs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AiReportProductTile(
                config: config,
                loading: _loadingProductId == config.id,
                answer: _answers[config.id],
                error: _errors[config.id],
                onGenerate: () => _generateReport(config),
              ),
            ),
          const SizedBox(height: 2),
          const _NoticeText(
            '当前使用服务端钱包：充值、扣费、退款和 AI 调用均通过统一 API 处理。AI 调用失败会自动退回本次扣费。',
          ),
          const SizedBox(height: 8),
          _NoticeText(AiReportProductCatalog.reportFooterCopy),
        ],
      ),
    );
  }

  Future<void> _generateReport(AiReportProductConfig config) async {
    final auth = ref.read(authStoreProvider);
    if (!auth.isAuthenticated) {
      setState(() {
        _errors[config.id] = '请先登录后再生成 AI 报告。';
      });
      context.push('/login');
      return;
    }

    if (!config.enabled) {
      setState(() {
        _errors[config.id] = config.disabledReason ?? '该报告暂未开放。';
      });
      return;
    }

    final focus = _focusController.text.trim();
    if (focus.isEmpty) {
      setState(() {
        _errors[config.id] = '请先输入想重点了解的事项。';
        _answers.remove(config.id);
      });
      return;
    }

    setState(() {
      _loadingProductId = config.id;
      _errors.remove(config.id);
      _answers.remove(config.id);
    });

    try {
      final result =
          await ref.read(walletStoreProvider.notifier).generateAiReport(
                productId: config.id,
                featureKey: config.featureKey,
                title: config.buttonTitle,
                systemPrompt: _systemPrompt,
                userPrompt: _buildUserPrompt(config, focus),
                temperature: 0.45,
                sourceJson: widget.sourceJson,
              );
      if (!mounted) return;
      setState(() {
        _answers[config.id] =
            result.answer.trim().isEmpty ? 'AI 服务未返回内容。' : result.answer.trim();
      });
    } on ServerWalletException catch (error) {
      if (error.wallet != null) {
        await ref
            .read(walletStoreProvider.notifier)
            .replaceFromServer(error.wallet!);
      }
      if (!mounted) return;
      setState(() {
        _errors[config.id] = error.statusCode == 402
            ? '${error.message}。请先充值后再生成。'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errors[config.id] = 'AI 报告生成失败，请稍后再试。');
    } finally {
      if (mounted) setState(() => _loadingProductId = null);
    }
  }

  String _buildUserPrompt(AiReportProductConfig config, String focus) {
    final template =
        AiReportPromptTemplates.templates[config.promptTemplateId] ?? '';
    final source = widget.sourceJson?.trim().isNotEmpty == true
        ? widget.sourceJson!.trim()
        : (widget.sourceSummary ?? '').trim();
    return [
      '用户重点想了解的事项：$focus',
      '功能：${config.featureKey}',
      '报告类型：${config.reportType}',
      '价格档位：${config.priceLabel}',
      '目标字数：${config.minWords}-${config.maxWords} 字',
      'promptTemplateId：${config.promptTemplateId}',
      '',
      '模板要求：',
      template,
      '',
      '本地结构化结果：',
      source,
      '',
      '请严格基于以上结构化结果生成中文报告。若结构化结果中没有某项信息，请明确说明“当前结果未提供该项，不作展开”。',
    ].join('\n');
  }

  static const _systemPrompt = '''
你是“国学万宝匣”的 AI 白话解读助手。
你只能根据应用本地已经生成的命盘、卦象或问事结构化结果进行解释。
禁止重新排盘、重新起卦、重新计算四柱、生成新的条文编号或编造不存在的数据。
禁止输出确定性断语，禁止使用“必然发财、必然离婚、必然生病、一定成功”等表达。
不得提供医疗、法律、投资等高风险现实决策结论。
报告需要通俗、温和、分层清楚，并在结尾加入传统文化参考免责声明。
''';
}

class _AiReportProductTile extends StatelessWidget {
  final AiReportProductConfig config;
  final bool loading;
  final String? answer;
  final String? error;
  final VoidCallback onGenerate;

  const _AiReportProductTile({
    required this.config,
    required this.loading,
    required this.answer,
    required this.error,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuoXueColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.primary.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.buttonTitle,
                      style: GuoXueTypography.body.copyWith(
                        color: GuoXueColors.inkBlack,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.enabled
                          ? config.buttonSubtitle
                          : (config.disabledReason ?? config.buttonSubtitle),
                      style: GuoXueTypography.caption.copyWith(
                        color: GuoXueColors.inkGray,
                        letterSpacing: 0,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${config.minWords}-${config.maxWords} 字 · 服务端扣费',
                      style: GuoXueTypography.caption.copyWith(
                        color: GuoXueColors.inkLight,
                        letterSpacing: 0,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                key: Key('ai_report_${config.id}'),
                onPressed: loading || !config.enabled ? null : onGenerate,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology_alt_outlined),
                label: Text(loading ? '生成中' : '生成报告'),
              ),
            ],
          ),
          if (loading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 6),
            Text(
              '正在提交服务端扣费并生成报告，请稍候。',
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.error,
                letterSpacing: 0,
                height: 1.4,
              ),
            ),
          ],
          if (answer != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              answer!,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoticeText extends StatelessWidget {
  final String text;

  const _NoticeText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GuoXueTypography.caption.copyWith(
        color: GuoXueColors.inkGray,
        letterSpacing: 0,
        height: 1.4,
      ),
    );
  }
}
