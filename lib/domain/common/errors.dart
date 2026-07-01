/// 领域层通用错误类型
class DomainException implements Exception {
  final String message;
  final Object? cause;

  const DomainException(this.message, {this.cause});

  @override
  String toString() => 'DomainException: $message${cause != null ? ' ($cause)' : ''}';
}

class InvalidInputException extends DomainException {
  const InvalidInputException(super.message, {super.cause});
}

class CalculationException extends DomainException {
  const CalculationException(super.message, {super.cause});
}
