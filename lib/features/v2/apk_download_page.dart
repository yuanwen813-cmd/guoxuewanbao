import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'apk_download_launcher.dart'
    if (dart.library.html) 'apk_download_launcher_web.dart';
import 'v2_page_scaffold.dart';

class ApkDownloadPage extends StatelessWidget {
  const ApkDownloadPage({super.key});

  static const apkPath = '/downloads/guoxuewanbao-latest.apk';
  static const apkFileName = 'guoxuewanbao-latest.apk';
  static const apkVersionLabel = '当前 Android 测试版';
  static const estimatedSize = '22.5 MB';

  @override
  Widget build(BuildContext context) {
    final downloadUrl = _absoluteDownloadUrl();
    return V2PageScaffold(
      title: '下载 Android App',
      subtitle: '下载安装国学万宝匣 Android 测试版。',
      icon: Icons.android,
      showAppBar: true,
      children: [
        _DownloadHero(downloadUrl: downloadUrl),
        const SizedBox(height: 12),
        _InfoCard(
          title: '安装说明',
          icon: Icons.install_mobile_outlined,
          children: const [
            _InfoLine('1. 点击下载按钮，保存 APK 安装包。'),
            _InfoLine('2. 如果手机提示“未知来源应用”，请允许当前浏览器安装。'),
            _InfoLine('3. 安装后从桌面图标打开，登录、钱包和 AI 解析仍使用公网服务端。'),
          ],
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          title: '版本说明',
          icon: Icons.info_outline,
          children: [
            _InfoLine('当前安装包为 Android 测试版，适合内部体验和人工测试。'),
            _InfoLine('暂未接入应用市场自动更新，后续新版需要重新下载安装。'),
            _InfoLine('如下载失败，可复制下载链接到手机浏览器打开。'),
          ],
        ),
      ],
    );
  }

  static String _absoluteDownloadUrl() {
    final base = Uri.base;
    return base.replace(path: apkPath, query: '', fragment: '').toString();
  }
}

class _DownloadHero extends StatelessWidget {
  final String downloadUrl;

  const _DownloadHero({required this.downloadUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GuoXueColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: GuoXueColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApkDownloadPage.apkVersionLabel,
                      style: GuoXueTypography.body.copyWith(
                        color: GuoXueColors.inkBlack,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ApkDownloadPage.apkFileName} · ${ApkDownloadPage.estimatedSize}',
                      style: GuoXueTypography.caption.copyWith(
                        color: GuoXueColors.inkGray,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('apk_download_button'),
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('下载 Android 安装包'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('apk_copy_link_button'),
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('复制下载链接'),
          ),
          const SizedBox(height: 10),
          SelectableText(
            downloadUrl,
            key: const Key('apk_download_url'),
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              letterSpacing: 0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final opened = await openApkDownload(downloadUrl);
    if (!context.mounted) return;
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已开始下载 APK 安装包')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: downloadUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制下载链接，可在浏览器中打开下载')),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: downloadUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('下载链接已复制')),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: GuoXueColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GuoXueTypography.body.copyWith(
                  color: GuoXueColors.inkBlack,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GuoXueTypography.caption.copyWith(
          color: GuoXueColors.inkGray,
          letterSpacing: 0,
          height: 1.45,
        ),
      ),
    );
  }
}
