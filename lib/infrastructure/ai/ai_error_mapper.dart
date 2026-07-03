/// AI 错误码到用户友好消息的映射
class AiErrorMapper {
  AiErrorMapper._();

  static String map(Object error) {
    final msg = error.toString();
    if (msg.contains('401')) {
      return 'AI 服务认证失败，请稍后再试。';
    }
    if (msg.contains('402')) {
      return 'AI 服务额度不足，请稍后再试。';
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
