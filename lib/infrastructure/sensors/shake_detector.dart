/// 摇动检测器 —— 封装 sensors_plus 加速度计
/// 用于金钱卦摇铜钱等场景
class ShakeDetector {
  bool _isListening = false;

  /// 摇动阈值 (m/s²)
  final double threshold;

  /// 摇动回调
  final VoidCallback? onShake;

  ShakeDetector({this.threshold = 15.0, this.onShake});

  /// 开始监听摇动
  Future<void> start() async {
    if (_isListening) return;
    _isListening = true;
    // TODO: 接入 sensors_plus accelerometerEvents
  }

  /// 停止监听
  void stop() {
    _isListening = false;
  }

  void dispose() => stop();
}

typedef VoidCallback = void Function();
