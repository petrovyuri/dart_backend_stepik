import 'package:auth/di/di_container.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Сервис для работы с JWT токенами.
///
/// Предоставляет функциональность для создания и верификации JWT токенов.
/// Используется для аутентификации и авторизации пользователей.
class JwtService {
  /// Создает экземпляр JWT сервиса.
  ///
  /// [di] - DI контейнер приложения для доступа к конфигурации и логгеру.
  JwtService(this.di);

  /// DI контейнер приложения.
  final DiContainer di;

  /// Создает пару токенов (access и refresh) для указанного пользователя.
  ///
  /// [userId] - идентификатор пользователя, для которого создаются токены.
  ///
  /// Возвращает кортеж из двух строк: (accessToken, refreshToken).
  (String, String) createTokens(int userId) {
    final accessToken = _createToken(userId, di.config.jwtAccessExp);
    final refreshToken = _createToken(userId, di.config.jwtRefreshExp);
    return (accessToken, refreshToken);
  }

  /// Создает access токен для пользователя.
  ///
  /// Access токен имеет короткое время жизни и используется для аутентификации
  /// запросов к защищенным ресурсам.
  ///
  /// [userId] - идентификатор пользователя.
  ///
  /// Возвращает подписанный JWT токен в виде строки.
  String _createToken(int userId, int exp) {
    // Создаем JWT объект с payload, содержащим:
    // - userId: идентификатор пользователя
    // - exp: время истечения (в минутах из конфига)
    // - iat: время создания токена (issued at)
    final jwt = JWT({'userId': userId, 'exp': exp, 'iat': DateTime.now().toUtc().toIso8601String()});

    // Подписываем токен секретным ключом и устанавливаем время жизни
    final token = jwt.sign(SecretKey(di.config.jwtSecret), expiresIn: Duration(minutes: exp));
    di.logger.debug('Token created: $token');
    return token;
  }

  /// Верифицирует JWT токен и извлекает payload.
  ///
  /// Проверяет подпись токена и его срок действия. Если токен валиден,
  /// возвращает содержимое payload. Если токен невалиден (истек срок,
  /// неверная подпись и т.д.), возвращает null.
  ///
  /// [token] - JWT токен в виде строки для верификации.
  ///
  /// Возвращает Map с данными payload токена, если токен валиден,
  /// иначе возвращает null.
  Map<String, dynamic>? verifyToken(String token) {
    try {
      // Верифицируем токен с использованием секретного ключа
      // Это проверит подпись и срок действия автоматически
      final jwt = JWT.verify(token, SecretKey(di.config.jwtSecret));

      // Извлекаем payload из токена
      final payload = jwt.payload as Map<String, dynamic>;
      return payload;
    } on Object catch (e, stackTrace) {
      // Логируем ошибку и возвращаем null при любой проблеме с токеном
      // (истек срок, неверная подпись, некорректный формат и т.д.)
      di.logger.error('Error verifying access token: $e', e, stackTrace);
      return null;
    }
  }
}
