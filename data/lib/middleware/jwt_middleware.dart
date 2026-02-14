import 'package:data/di/di_container.dart';
import 'package:shelf/shelf.dart';

/// Расширение для удобного доступа к userId из контекста
extension RequestUserIdExtension on Request {
  /// Получает userId из контекста запроса
  int? get userId => context['userId'] as int?;

  /// Получает payload токена из контекста запроса
  Map<String, dynamic>? get tokenPayload => context['tokenPayload'] as Map<String, dynamic>?;
}

/// Middleware для проверки JWT токена и добавления userId в контекст
class JwtMiddleware {
  JwtMiddleware(this.di);

  final DiContainer di;

  /// Создает middleware handler
  Middleware get handler {
    return (Handler innerHandler) {
      return (Request request) async {
        // Проверяем, является ли это межсервисным вызовом
        final internalSecretHeader = request.headers['x-internal-secret'];
        if (internalSecretHeader != null && internalSecretHeader == di.config.internalSecret) {
          // Межсервисный вызов - пропускаем проверку JWT
          return await innerHandler(request);
        }

        // Извлекаем токен из заголовка Authorization
        final authHeader = request.headers['authorization'];

        // Проверяем, что заголовок Authorization присутствует
        if (authHeader == null || authHeader.isEmpty) {
          di.logger.info('Authorization header отсутствует');
          return Response.unauthorized("Authorization header отсутствует");
        }

        // Проверяем формат Bearer токена
        if (!authHeader.startsWith('Bearer ')) {
          di.logger.info('Неверный формат токена: $authHeader');
          return Response.unauthorized("Неверный формат токена");
        }

        // Извлекаем токен
        final token = authHeader.substring(7); // Убираем "Bearer "

        // Верифицируем токен
        final payload = di.jwtService.verifyToken(token);

        // Проверяем, что токен валидный
        if (payload == null) {
          di.logger.info('Токен невалидный или истек');
          return Response.unauthorized("Токен невалидный или истек");
        }

        // Извлекаем userId из payload
        final userId = payload['userId'] as int?;

        // Проверяем, что userId присутствует в токене
        if (userId == null) {
          di.logger.info('userId отсутствует в токене');
          return Response.unauthorized("userId отсутствует в токене");
        }

        di.logger.debug('Токен успешно верифицирован для userId: $userId');

        // Добавляем userId в контекст запроса
        final updatedRequest = request.change(context: {'userId': userId, 'tokenPayload': payload});

        // Передаем запрос дальше по цепочке
        return await innerHandler(updatedRequest);
      };
    };
  }
}
