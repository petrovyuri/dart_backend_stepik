part of 'app_handlers.dart';

/// Обработчик HTTP-запроса для входа пользователя в систему (sign in).
///
/// Этот обработчик является точкой входа для аутентификации пользователя.
/// Он извлекает email и пароль из тела HTTP-запроса, валидирует их,
/// и передает управление функции [_processSignIn] для выполнения логики входа.
///
/// [request] - HTTP-запрос, содержащий email и пароль в теле запроса (JSON)
/// [di] - контейнер зависимостей, предоставляющий доступ к сервисам
///
/// Возвращает HTTP-ответ:
/// - 200 OK с токенами доступа при успешной аутентификации
/// - 400 Bad Request при ошибках валидации входных данных
/// - 404 Not Found если пользователь не найден
/// - 401 Unauthorized при неверном пароле
/// - 500 Internal Server Error при внутренних ошибках сервера
Future<Response> _signInHandler(Request request, DiContainer di) async {
  // Извлекаем и валидируем email и пароль из тела HTTP-запроса
  // Метод выполняет проверки на наличие полей, их непустоту,
  // валидность формата email и минимальную длину пароля
  final result = await HandlerUtil.extractEmailAndPassword(request);

  // Используем pattern matching (switch expression) для обработки результата извлечения
  // Это современный подход Dart 3.0 для безопасной обработки sealed классов
  return switch (result) {
    // Если произошла ошибка при извлечении данных (невалидный формат, отсутствие полей и т.д.),
    // возвращаем готовый HTTP-ответ с описанием ошибки
    ExtractError(:final response) => response,
    // Если данные успешно извлечены, передаем их в функцию обработки входа
    ExtractSuccess(:final email, :final password) => await _processSignIn(email, password, di),
  };
}

/// Выполняет основную логику аутентификации пользователя.
///
/// Процесс аутентификации включает следующие шаги:
/// 1. Поиск пользователя в базе данных по email
/// 2. Проверка существования пользователя
/// 3. Верификация пароля путем сравнения хеша введенного пароля с сохраненным хешем
/// 4. Генерация JWT токенов (access и refresh) при успешной аутентификации
/// 5. Возврат токенов и информации о пользователе клиенту
///
/// [email] - email пользователя, прошедший валидацию
/// [password] - пароль пользователя в открытом виде (будет проверен через хеш)
/// [di] - контейнер зависимостей с сервисами для работы с БД, хешированием и JWT
///
/// Возвращает HTTP-ответ с результатом аутентификации
Future<Response> _processSignIn(String email, String password, DiContainer di) async {
  // Логируем попытку входа для отладки (в production пароль не должен логироваться)
  di.logger.debug('Email: $email, Password: $password');

  try {
    // Шаг 1: Ищем пользователя в базе данных по email
    // Если пользователь не найден, метод вернет null
    final user = await di.userService.getUserByEmail(email);

    // Шаг 2: Проверяем, существует ли пользователь с таким email
    if (user == null) {
      // Возвращаем 404 Not Found, чтобы не раскрывать информацию о существовании email
      // (альтернативный подход - возвращать 401 для безопасности)
      return Response.notFound(
        await HandlerUtil.bodyToJson(message: "Пользователь не найден", code: CodeAction.userNotFoundByEmail),
      );
    }

    // Шаг 3: Верифицируем пароль
    // Сравниваем хеш введенного пароля с сохраненным хешем в базе данных
    // Используется безопасное сравнение хешей для предотвращения timing attacks
    if (!di.hashService.verifyData(password, user.password)) {
      // Пароль неверный - возвращаем 401 Unauthorized
      // Сообщение "Email или пароль неверны" используется для безопасности,
      // чтобы не раскрывать, какое именно поле неверно
      return Response.unauthorized(
        await HandlerUtil.bodyToJson(
          message: "Email или пароль неверны",
          code: CodeAction.authenticationError,
        ),
      );
    }

    // Шаг 4: Все проверки пройдены - генерируем JWT токены
    // Access token - для доступа к защищенным ресурсам (короткоживущий)
    // Refresh token - для обновления access token (долгоживущий)
    // Токены содержат идентификатор пользователя (user.id)
    final (accessToken, refreshToken) = di.jwtService.createTokens(user.id);

    // Шаг 5: Возвращаем успешный ответ с токенами и информацией о пользователе
    return Response.ok(
      jsonEncode({
        'access_token': accessToken, // JWT токен для доступа к API
        'refresh_token': refreshToken, // JWT токен для обновления access token
        'id': user.id, // Уникальный идентификатор пользователя
        'email': email, // Email пользователя (возвращаем оригинальный из запроса)
      }),
    );
  } on Object catch (e, stackTrace) {
    // Обработка любых неожиданных ошибок (ошибки БД, сервисов и т.д.)
    // Логируем полную информацию об ошибке для последующего анализа
    di.logger.error('Ошибка при аутентификации: $e', e, stackTrace);

    // Возвращаем общий ответ об ошибке, не раскрывая детали клиенту
    // для безопасности (чтобы не дать злоумышленнику информацию о внутренней структуре)
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(message: "Ошибка при аутентификации", code: CodeAction.signinError),
    );
  }
}
