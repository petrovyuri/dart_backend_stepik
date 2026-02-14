part of 'app_handlers.dart';

/// Обработчик для обновления access токена с помощью refresh токена
Future<Response> _refreshTokenHandler(Request request, DiContainer di) async {
  try {
    // Получаем тело запроса
    final body = await request.readAsString();

    // Проверяем, что тело запроса не пустое, так как в теле
    // запроса должен быть refresh token
    if (body.isEmpty) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(message: 'Тело запроса пустое', code: CodeAction.bodyIsEmpty),
      );
    }

    // Декодируем тело запроса
    final json = jsonDecode(body) as Map<String, dynamic>;

    // Получаем refresh token из тела запроса
    final refreshToken = json['refresh_token'] as String?;

    // Проверяем, что refresh token не пустой
    if (refreshToken == null || refreshToken.isEmpty) {
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(
          message: 'Refresh token обязателен',
          code: CodeAction.refreshTokenRequired,
        ),
      );
    }

    // Верифицируем refresh токен
    final payload = di.jwtService.verifyToken(refreshToken);

    // Если refresh токен невалидный или истек
    if (payload == null) {
      return Response.unauthorized(
        await HandlerUtil.bodyToJson(
          message: 'Refresh token невалидный или истек',
          code: CodeAction.authorizationTokenInvalid,
        ),
      );
    }

    // Извлекаем userId из payload
    final userId = payload['userId'] as int?;

    // Если userId не найден, ошибка
    if (userId == null) {
      return Response.internalServerError(
        body: await HandlerUtil.bodyToJson(
          message: 'Ошибка при обработке токена',
          code: CodeAction.authorizationTokenProcessingError,
        ),
      );
    }

    // Проверяем, существует ли пользователь
    final user = await di.userService.getUserById(userId);
    if (user == null) {
      return Response.notFound(
        await HandlerUtil.bodyToJson(message: 'Пользователь не найден', code: CodeAction.userNotFoundById),
      );
    }

    // Создаем новую пару токенов
    final (newAccessToken, newRefreshToken) = di.jwtService.createTokens(userId);

    return Response.ok(jsonEncode({'access_token': newAccessToken, 'refresh_token': newRefreshToken}));
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при обновлении токена: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при обновлении токена',
        code: CodeAction.refreshTokenError,
      ),
    );
  }
}
