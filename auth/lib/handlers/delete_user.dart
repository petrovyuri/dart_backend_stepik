part of 'app_handlers.dart';

Future<Response> _deleteUserHandler(Request request, DiContainer di) async {
  try {
    final userId = request.userId;
    if (userId == null) {
      return Response.unauthorized(
        await HandlerUtil.bodyToJson(
          message: 'userId отсутствует в контексте запроса',
          code: CodeAction.authorizationTokenProcessingError,
        ),
      );
    }
    return await _processDeleteUser(userId, di);
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при удалении пользователя: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при удалении пользователя',
        code: CodeAction.parseErrorInUserRequest,
      ),
    );
  }
}

Future<Response> _processDeleteUser(int userId, DiContainer di) async {
  try {
    final deletedCount = await di.userService.deleteUser(userId);
    if (deletedCount == 0) {
      return Response.notFound(
        await HandlerUtil.bodyToJson(message: 'Пользователь не найден', code: CodeAction.userNotFoundById),
      );
    }
    await _processDeleteUserPosts(userId, di);
    return Response.ok(
      await HandlerUtil.bodyToJson(message: 'Пользователь успешно удален', code: CodeAction.userDeleted),
    );
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при удалении пользователя: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при удалении пользователя',
        code: CodeAction.parseErrorInUserRequest,
      ),
    );
  }
}

/// Удаляет все посты пользователя через API сервиса data
Future<void> _processDeleteUserPosts(int userId, DiContainer di) async {
  try {
    // Удаляем посты пользователя через API сервиса data
    await di.dataService.deleteUserPostsViaApi(userId);
    di.logger.info('Посты пользователя $userId удалены через API');
  } on Object catch (e, stackTrace) {
    // Логируем ошибку
    di.logger.error('Ошибка при удалении постов пользователя: $e', e, stackTrace);
  }
}
