/// AI 错误码到用户友好消息的映射
class AiErrorMapper {
  AiErrorMapper._();

  static String map(Object error) {
    final msg = error.toString();
    if (msg.contains('401')) {
      return 'API Key 无效，请检查设置。';
    }
    if (msg.contains('402')) {
      return 'API 额度不足，请检查账户。';
    }
    if (msg.contains('429')) {
      return '请求太频繁，请稍后重试。';
    }
    if (msg.contains('timeout') || msg.contains('超时')) {
      return 'AI 响应超时，请检查网络后重试。';
    }
    return 'AI 服务暂时不可用，请稍后重试。';
  }
}
