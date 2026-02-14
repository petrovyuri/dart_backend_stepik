/// Коды действий для обработки ошибок
abstract final class CodeAction {
  /// Ошибка при входе в систему
  static const String signinError = "000";

  /// Ошибка при регистрации
  static const String signUpError = "001";

  /// Email или пароль не указаны
  static const String emailOrPasswordRequired = "002";

  /// Пользователь не найден по email
  static const String userNotFoundByEmail = "003";

  /// Пользователь уже существует
  static const String userAlreadyExists = "004";

  /// Ошибка аутентификации
  static const String authenticationError = "005";

  /// Тело запроса пустое
  static const String bodyIsEmpty = "006";

  /// Email не указан
  static const String emailRequired = "007";

  /// Пароль не указан
  static const String passwordRequired = "008";

  /// Ошибка парсинга запроса пользователя
  static const String parseErrorInUserRequest = "009";

  /// Email невалидный
  static const String emailInvalid = "010";

  /// Пароль невалидный
  static const String passwordInvalid = "011";

  /// Токен авторизации отсутствует
  static const String authorizationTokenMissing = "012";

  /// Токен авторизации невалидный формат
  static const String authorizationTokenInvalidFormat = "013";

  /// Токен авторизации невалидный
  static const String authorizationTokenInvalid = "014";

  /// Ошибка обработки токена авторизации
  static const String authorizationTokenProcessingError = "015";

  /// Пользователь не найден по id
  static const String userNotFoundById = "016";

  /// Пользователь удален
  static const String userDeleted = "017";

  /// Пользователь обновлен
  static const String userUpdated = "018";

  /// Токен обновления отсутствует
  static const String refreshTokenRequired = "019";

  /// Ошибка токена обновления
  static const String refreshTokenError = "020";

  /// Превышено количество запросов
  static const String rateLimitExceeded = "021";
}
