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
