part of 'app_handlers.dart';

/// Обработчик для получения списка всех постов пользователя (с пагинацией)
Future<Response> _getPostsHandler(Request request, DiContainer di) async {
  // ШАГ 1: Проверка авторизации
  final userId = request.userId;
  if (userId == null) {
    return Response.unauthorized(
      await HandlerUtil.bodyToJson(
        message: 'Ошибка авторизации',
        code: CodeAction.authorizationTokenProcessingError,
      ),
    );
  }

  try {
    // ШАГ 2: Извлекаем параметры пагинации из Query Params
    // Пример URL: /posts?limit=5&offset=10
    final queryParams = request.url.queryParameters;

    // Пытаемся прочитать limit (по умолчанию 10)
    final limit = int.tryParse(queryParams['limit'] ?? '') ?? 10;
    // Пытаемся прочитать offset (по умолчанию 0)
    final offset = int.tryParse(queryParams['offset'] ?? '') ?? 0;

    // ШАГ 3: Запрашиваем данные у сервиса
    final posts = await di.postService.getPosts(userId, limit: limit, offset: offset);

    // ШАГ 4: Превращаем список объектов PostData в список Map для JSON
    final postsJson = posts
        .map(
          (post) => {'id': post.id, 'authorId': post.authorId, 'title': post.title, 'content': post.content},
        )
        .toList();

    di.logger.info('Отправлено ${posts.length} постов для userId=$userId');

    // ШАГ 5: Возвращаем результат
    return Response.ok(jsonEncode(postsJson));
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при получении списка постов: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(message: 'Ошибка сервера', code: CodeAction.getPostsError),
    );
  }
}
