/// 统一结果类型，用于领域层和用例层的错误处理
sealed class DomainResult<T> {
  const DomainResult();
}

final class Success<T> extends DomainResult<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends DomainResult<T> {
  final String message;
  final Object? cause;
  const Failure(this.message, {this.cause});
}
