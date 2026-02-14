part of 'app_handlers.dart';

/// Обработчик HTTP-запроса на регистрацию нового пользователя.
///
/// Извлекает email и пароль из тела запроса и делегирует
/// обработку функции [_processSignUp].
Future<Response> _signUpHandler(Request request, DiContainer di) async {
  // Извлекаем email и пароль из тела запроса
  final result = await HandlerUtil.extractEmailAndPassword(request);

  // Используем pattern matching для обработки результата
  return switch (result) {
    // Если произошла ошибка извлечения данных - возвращаем ошибку
    ExtractError(:final response) => response,
    // Если данные извлечены успешно - обрабатываем регистрацию
    ExtractSuccess(:final email, :final password) => await _processSignUp(email, password, di),
  };
}

/// Обрабатывает регистрацию нового пользователя.
///
/// Проверяет, существует ли пользователь с указанным email.
/// Если пользователь существует - возвращает ошибку.
/// Если нет - создает нового пользователя и возвращает токены доступа.
Future<Response> _processSignUp(String email, String password, DiContainer di) async {
  di.logger.debug('Email: $email, Password: $password');

  try {
    // Проверяем, существует ли пользователь с таким email
    final user = await di.userService.getUserByEmail(email);
    if (user != null) {
      // Пользователь уже существует - возвращаем ошибку
      return Response.badRequest(
        body: await HandlerUtil.bodyToJson(
          message: "Пользователь уже существует",
          code: CodeAction.userAlreadyExists,
        ),
      );
    }

    // Создаем нового пользователя и получаем его ID
    final id = await di.userService.createUser(email, password);

    // Генерируем JWT токены (access и refresh) для нового пользователя
    final (accessToken, refreshToken) = di.jwtService.createTokens(id);

    // Возвращаем успешный ответ с токенами и данными пользователя
    return Response.ok(
      jsonEncode({
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'id': id,
        'email': email, // Возвращаем оригинальный email из запроса
      }),
    );
  } on Object catch (e, stackTrace) {
    // Логируем ошибку и возвращаем ответ об ошибке сервера
    di.logger.error('Ошибка при создании пользователя: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при создании пользователя',
        code: CodeAction.signUpError,
      ),
    );
  }
}
