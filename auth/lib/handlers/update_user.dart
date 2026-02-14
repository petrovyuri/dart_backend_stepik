part of 'app_handlers.dart';

Future<Response> _updateUserHandler(Request request, DiContainer di) async {
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
    final result = await HandlerUtil.extractEmailAndPassword(request);
    return switch (result) {
      ExtractError(:final response) => response,
      ExtractSuccess(:final email, :final password) => await _processUpdateUser(email, password, userId, di),
    };
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при обновлении пользователя: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при обновлении пользователя',
        code: CodeAction.parseErrorInUserRequest,
      ),
    );
  }
}

Future<Response> _processUpdateUser(String email, String password, int userId, DiContainer di) async {
  try {
    final updatedCount = await di.userService.updateUser(userId, email, password);
    if (updatedCount == 0) {
      return Response.notFound(
        await HandlerUtil.bodyToJson(message: 'Пользователь не найден', code: CodeAction.userNotFoundById),
      );
    }
    return Response.ok(
      await HandlerUtil.bodyToJson(message: 'Пользователь успешно обновлен', code: CodeAction.userUpdated),
    );
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при обновлении пользователя: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при обновлении пользователя',
        code: CodeAction.parseErrorInUserRequest,
      ),
    );
  }
}
