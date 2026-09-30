typedef ValidationLogic<T> = bool Function(T? value);

class ValidationRule<T> {
  ValidationRule({
    required ValidationLogic<T> logic,
    required String errorMessage,
  }) : _logic = logic,
       _errorMessage = errorMessage;

  final ValidationLogic<T> _logic;
  final String _errorMessage;

  ValidationLogic<T> get logic => _logic;
  String get errorMessage => _errorMessage;

  /// Returns the errorMessage if the logic returns false (invalid),
  /// otherwise returns null.
  String? validate(T? value) {
    return logic(value) ? null : errorMessage;
  }
}

/// A collection of reusable, atomic rules
class GlobalRules {
  static ValidationRule<String> required(String fieldName) => ValidationRule(
    logic: (value) => value != null && value.trim().isNotEmpty,
    errorMessage: "$fieldName is required",
  );
}
