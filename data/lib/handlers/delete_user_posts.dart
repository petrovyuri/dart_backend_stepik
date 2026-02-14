part of 'app_handlers.dart';

/// Обработчик для удаления всех постов конкретного пользователя.
///
/// Данный обработчик поддерживает два режима работы:
/// 1. **Межсервисный вызов**: При наличии секретного заголовка "x-internal-secret",
///    который совпадает с настроенным в конфиге, проверка авторизации через JWT пропускается.
///    Это используется для каскадного удаления данных при удалении аккаунта пользователя другом сервисом.
/// 2. **Обычный вызов**: Требует валидный JWT токен. Пользователь может удалять только свои посты.
///
/// Параметры:
/// - [request]: Объект запроса Shelf.
/// - [di]: Контейнер зависимостей (Dependency Injection).
/// - [userId]: ID пользователя, чьи посты необходимо удалить (передается как строка из пути).
///
/// Возвращает [Response] со статусом выполнения и количеством удаленных записей.
Future<Response> _deleteUserPostsHandler(Request request, DiContainer di, String userId) async {
  try {
    // Пытаемся преобразовать строковый ID пользователя в целое число
    final requestedUserId = int.tryParse(userId);

    // Если ID некорректен, возвращаем ошибку 400 Bad Request
    if (requestedUserId == null) {
      return Response(
        400,
        body: await HandlerUtil.bodyToJson(
          message: 'Некорректный ID пользователя',
          code: CodeAction.invalidPostData,
        ),
      );
    }

    // Проверяем, является ли это доверенным межсервисным вызовом по секретному заголовку
    final internalSecretHeader = request.headers['x-internal-secret'];
    final isInternalCall = internalSecretHeader != null && internalSecretHeader == di.config.internalSecret;

    if (isInternalCall) {
      // Для межсервисных вызовов логируем событие и пропускаем проверку JWT
      di.logger.info('Межсервисный вызов для удаления постов пользователя $requestedUserId');
    } else {
      // Для обычных пользовательских вызовов проверяем наличие ID пользователя в JWT токене
      final tokenUserId = request.userId;
      if (tokenUserId == null) {
        return Response.unauthorized(
          await HandlerUtil.bodyToJson(
            message: 'Требуется авторизация',
            code: CodeAction.authorizationTokenMissing,
          ),
        );
      }

      // Бизнес-логика: обычный пользователь может инициировать удаление только собственных постов
      if (tokenUserId != requestedUserId) {
        return Response.forbidden(
          await HandlerUtil.bodyToJson(
            message: 'Нет доступа к удалению постов другого пользователя',
            code: CodeAction.authorizationTokenProcessingError,
          ),
        );
      }
    }

    // Вызываем сервис для непосредственного удаления постов из базы данных
    final deletedCount = await di.postService.deletePostsByUserId(requestedUserId);

    // Возвращаем успешный ответ с информацией о количестве удаленных постов
    return Response.ok(
      await HandlerUtil.bodyToJson(message: 'Удалено постов: $deletedCount', code: CodeAction.postDeleted),
    );
  } on Object catch (e, stackTrace) {
    // В случае непредвиденных ошибок логируем их и возвращаем 500 Internal Server Error
    di.logger.error('Ошибка при удалении постов пользователя: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при удалении постов пользователя',
        code: CodeAction.deletePostError,
      ),
    );
  }
}
