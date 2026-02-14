part of 'app_handlers.dart';

/// Handler для создания поста
Future<Response> _createPostHandler(Request request, DiContainer di) async {
  // Получаем userId из контекста (добавлен JWT middleware)
  final userId = request.userId;
  // Проверяем userId
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
    // Читаем body запроса
    final body = await request.readAsString();
    if (body.isEmpty) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(message: 'Тело запроса пустое', code: CodeAction.invalidPostData),
      );
    }

    // Парсим JSON
    final jsonData = jsonDecode(body) as Map<String, dynamic>;
    final title = jsonData['title'] as String?;
    final content = jsonData['content'] as String?;

    // Валидация данных
    if (title == null || title.isEmpty) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(
          message: 'Поле title обязательно и не может быть пустым',
          code: CodeAction.invalidPostData,
        ),
      );
    }

    if (content == null || content.isEmpty) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(
          message: 'Поле content обязательно и не может быть пустым',
          code: CodeAction.invalidPostData,
        ),
      );
    }

    if (title.length > 255) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(
          message: 'Поле title не может быть длиннее 255 символов',
          code: CodeAction.invalidPostData,
        ),
      );
    }

    final postId = await di.postService.createPost(userId, title, content);

    di.logger.info('Пост создан: id=$postId, authorId=$userId, title=$title');

    // Возвращаем созданный пост
    return Response.ok(jsonEncode({'id': postId, 'authorId': userId, 'title': title, 'content': content}));
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при создании поста: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при создании поста',
        code: CodeAction.createPostError,
      ),
    );
  }
}
