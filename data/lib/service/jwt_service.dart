import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:data/di/di_container.dart';

/// Сервис для работы с JWT токенами
class JwtService {
  JwtService(this.di);

  final DiContainer di;

  /// Верифицирует access токен
  Map<String, dynamic>? verifyToken(String token) {
    try {
      // Сверяем токен с секретом
      final jwt = JWT.verify(token, SecretKey(di.config.JWTSecret));

      // Получаем payload
      final payload = jwt.payload as Map<String, dynamic>;
      return payload;
    } on Object catch (e, stackTrace) {
      di.logger.error('Ошибка при верификации токена $e', e, stackTrace);
      return null;
    }
  }
}
