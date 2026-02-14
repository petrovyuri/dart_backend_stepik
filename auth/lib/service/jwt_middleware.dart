import 'package:auth/di/di_container.dart';
import 'package:auth/handlers/code_action.dart';
import 'package:auth/handlers/handler_utils.dart';
import 'package:shelf/shelf.dart';

/// Middleware для проверки JWT токена и добавления userId в контекст запроса.
///
/// Этот middleware выполняет следующие функции:
/// 1. Проверяет наличие заголовка Authorization
/// 2. Валидирует формат токена (должен начинаться с "Bearer ")
/// 3. Верифицирует JWT токен через JwtService
/// 4. Извлекает userId из payload токена
/// 5. Добавляет userId и payload в контекст запроса для использования в обработчиках
class JwtMiddleware {
  /// Конструктор принимает контейнер зависимостей для доступа к сервисам (JwtService, Logger)
  JwtMiddleware(this.di);

  /// Контейнер зависимостей, предоставляющий доступ к сервисам приложения
  /// (JwtService для верификации токенов, Logger для логирования)
  final DiContainer di;

  /// Создает и возвращает middleware handler для использования в цепочке middleware.
  ///
  /// Middleware handler - это функция, которая принимает следующий обработчик в цепочке
  /// и возвращает новый обработчик, который выполняет проверку токена перед вызовом
  /// следующего обработчика.
  Middleware get handler {
    return (Handler innerHandler) {
      // Возвращаем функцию-обработчик запросов
      return (Request request) async {
        // ============================================================
        // ШАГ 1: Проверка наличия заголовка Authorization
        // ============================================================
        // Извлекаем значение заголовка Authorization из запроса
        // Заголовок должен содержать JWT токен в формате "Bearer <token>"
        final authHeader = request.headers['authorization'];

        // Если заголовок отсутствует или пустой, возвращаем ошибку 401 (Unauthorized)
        if (authHeader == null || authHeader.isEmpty) {
          di.logger.info('Authorization header отсутствует');
          return Response.unauthorized(
            await HandlerUtil.bodyToJson(
              message: 'Токен авторизации отсутствует',
              code: CodeAction.authorizationTokenMissing,
            ),
          );
        }

        // ============================================================
        // ШАГ 2: Проверка формата токена (должен начинаться с "Bearer ")
        // ============================================================
        // Согласно стандарту RFC 6750, токен должен передаваться в формате:
        // Authorization: Bearer <token>
        if (!authHeader.startsWith('Bearer ')) {
          di.logger.info('Неверный формат токена: $authHeader');
          return Response.unauthorized(
            await HandlerUtil.bodyToJson(
              message: 'Неверный формат токена',
              code: CodeAction.authorizationTokenInvalidFormat,
            ),
          );
        }

        // ============================================================
        // ШАГ 3: Извлечение токена из заголовка
        // ============================================================
        // Убираем префикс "Bearer " (7 символов), чтобы получить чистый JWT токен
        final token = authHeader.substring(7); // Убираем "Bearer "

        // ============================================================
        // ШАГ 4: Верификация JWT токена
        // ============================================================
        // Проверяем токен через JwtService: валидность подписи, срок действия и т.д.
        // Если токен валиден, получаем payload (данные внутри токена)
        // Если токен невалиден (подпись неверна, срок истек и т.д.), вернется null
        final payload = di.jwtService.verifyToken(token);

        if (payload == null) {
          di.logger.info('Токен невалидный или истек');
          return Response.unauthorized(
            await HandlerUtil.bodyToJson(
              message: 'Токен невалидный или истек',
              code: CodeAction.authorizationTokenInvalid,
            ),
          );
        }

        // ============================================================
        // ШАГ 5: Извлечение userId из payload токена
        // ============================================================
        // Из payload (полезной нагрузки) токена извлекаем userId - идентификатор пользователя
        // userId должен быть целым числом (int)
        final userId = payload['userId'] as int?;

        // Если userId отсутствует в токене, это критическая ошибка сервера
        // (токен должен всегда содержать userId)
        if (userId == null) {
          di.logger.info('userId отсутствует в токене');
          return Response.internalServerError(
            body: await HandlerUtil.bodyToJson(
              message: 'Ошибка при обработке токена',
              code: CodeAction.authorizationTokenProcessingError,
            ),
          );
        }

        // Логируем успешную верификацию токена (уровень debug для отладки)
        di.logger.debug('Токен успешно верифицирован для userId: $userId');

        // ============================================================
        // ШАГ 6: Добавление данных в контекст запроса
        // ============================================================
        // Создаем новый запрос с добавленными данными в контекст:
        // - userId: идентификатор пользователя (для использования в обработчиках)
        // - tokenPayload: весь payload токена (на случай, если нужны другие данные)
        // Контекст доступен через request.context в последующих обработчиках
        final updatedRequest = request.change(context: {'userId': userId, 'tokenPayload': payload});

        // ============================================================
        // ШАГ 7: Передача запроса следующему обработчику
        // ============================================================
        // Передаем обновленный запрос (с userId в контексте) следующему обработчику
        // в цепочке middleware/handlers
        return await innerHandler(updatedRequest);
      };
    };
  }
}
