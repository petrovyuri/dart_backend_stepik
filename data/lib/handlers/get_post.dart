part of 'app_handlers.dart';

/// Обработчик (Handler) для получения одного конкретного поста по его ID
Future<Response> _getPostHandler(Request request, DiContainer di, [String? postIdParam]) async {
  // ШАГ 1: Проверяем, авторизован ли пользователь.
  // Мы достаем ID пользователя, который туда заботливо положил наш JWT Middleware.
  final userId = request.userId;

  // Если ID нет — значит, пользователь не вошел в систему.
  if (userId == null) {
    di.logger.info('userId отсутствует в контексте запроса');
    return Response.unauthorized(
      await HandlerUtil.bodyToJson(
        message: 'Ошибка авторизации',
        code: CodeAction.authorizationTokenProcessingError,
      ),
    );
  }

  try {
    // Пытаемся понять, какой именно пост нужен пользователю.
    // ID может прийти либо в параметре postIdParam, либо быть последним кусочком URL.
    final postIdStr = postIdParam ?? request.url.pathSegments.last;
    final postId = int.tryParse(postIdStr);

    // Если вместо цифр нам прислали какой-то мусор — отвечаем, что ID некорректный.
    if (postId == null) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(
          message: 'Некорректный ID поста',
          code: CodeAction.invalidPostData,
        ),
      );
    }

    // Запрашиваем пост у нашей "службы постов" (PostService).
    // Мы передаем ID поста и того, кто его запрашивает.
    final post = await di.postService.getPost(postId, userId);

    // Если такого поста не существует (или он принадлежит не этому пользователю)
    if (post == null) {
      return Response.notFound(
        await HandlerUtil.bodyToJson(message: 'Пост не найден', code: CodeAction.postNotFound),
      );
    }

    // Формируем ответ.
    // Если всё хорошо, превращаем данные поста в обычный JSON-объект.
    final postJson = {'id': post.id, 'authorId': post.authorId, 'title': post.title, 'content': post.content};

    di.logger.info('Получен пост: postId=$postId, userId=$userId');

    // ШАГ 5: Отправляем результат пользователю со статусом 200 (OK).
    return Response.ok(jsonEncode(postJson));
  } on Object catch (e, stackTrace) {
    // Если что-то сломалось на уровне сервера — записываем ошибку в лог и сообщаем клиенту.
    di.logger.error('Ошибка при получении поста: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при получении поста',
        code: CodeAction.getPostError,
      ),
    );
  }
}
