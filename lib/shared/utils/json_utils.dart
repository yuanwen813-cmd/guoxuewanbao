import 'dart:convert';

/// JSON 工具
class JsonUtils {
  JsonUtils._();

  /// 安全 JSON 解码，失败返回 null
  static Map<String, dynamic>? safeDecode(String raw) {
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 安全 JSON 编码
  static String safeEncode(Map<String, dynamic> data) {
    try {
      return json.encode(data);
    } catch (_) {
      return '{}';
    }
  }
}
