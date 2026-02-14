import 'dart:convert';

import 'package:auth/handlers/code_action.dart';
import 'package:shelf/shelf.dart';

/// Результат извлечения данных из запроса.
///
/// Используется для представления результата валидации и извлечения
/// email и пароля из HTTP-запроса. Поддерживает два типа результата:
/// успешное извлечение ([ExtractSuccess]) и ошибку ([ExtractError]).
sealed class ExtractResult {}

/// Успешное извлечение данных из запроса.
///
/// Содержит валидированные и извлеченные из запроса email и пароль.
final class ExtractSuccess extends ExtractResult {
  ExtractSuccess(this.email, this.password);

  /// Email пользователя, прошедший валидацию
  final String email;

  /// Пароль пользователя, прошедший валидацию
  final String password;
}

/// Ошибка при извлечении данных из запроса.
///
/// Содержит HTTP-ответ с описанием ошибки, который будет возвращен клиенту.
final class ExtractError extends ExtractResult {
  ExtractError(this.response);

  /// HTTP-ответ с описанием ошибки
  final Response response;
}

/// Утилитный класс для обработки HTTP-запросов.
///
/// Предоставляет статические методы для извлечения и валидации данных
/// из HTTP-запросов, а также для формирования JSON-ответов.
abstract class HandlerUtil {
  /// Извлекает и валидирует email и пароль из тела HTTP-запроса.
  ///
  /// Выполняет следующие проверки:
  /// 1. Проверяет, что тело запроса не пустое
  /// 2. Парсит JSON из тела запроса
  /// 3. Проверяет наличие и непустоту email
  /// 4. Проверяет наличие и непустоту пароля
  /// 5. Валидирует формат email (содержит @ и точку, длина > 3 символов)
  /// 6. Валидирует длину пароля (не менее 8 символов)
  ///
  /// [request] - HTTP-запрос, из которого извлекаются данные
  ///
  /// Возвращает [ExtractSuccess] с валидными данными при успехе,
  /// или [ExtractError] с описанием ошибки при неудаче.
  static Future<ExtractResult> extractEmailAndPassword(Request request) async {
    try {
      // Читаем тело запроса как строку
      final body = await request.readAsString();

      // Проверка на пустое тело запроса
      if (body.isEmpty) {
        return ExtractError(
          Response.badRequest(
            body: await bodyToJson(message: 'Тело запроса пустое', code: CodeAction.bodyIsEmpty),
          ),
        );
      }

      // Парсим JSON из тела запроса
      // Ожидаем объект с полями email и password
      final json = jsonDecode(body) as Map<String, dynamic>;
      final email = json['email'] as String?;
      final password = json['password'] as String?;

      // Валидация наличия email
      if (email == null || email.isEmpty) {
        return ExtractError(
          Response.badRequest(
            body: await bodyToJson(message: 'Email обязателен', code: CodeAction.emailRequired),
          ),
        );
      }

      // Валидация наличия пароля
      if (password == null || password.isEmpty) {
        return ExtractError(
          Response.badRequest(
            body: await bodyToJson(message: 'Пароль обязателен', code: CodeAction.passwordRequired),
          ),
        );
      }

      // Валидация формата email: должен содержать @ и точку, длина > 3 символов
      // Это базовая валидация, для production лучше использовать регулярные выражения
      if (!(email.contains('@') && email.contains('.') && email.length > 3)) {
        return ExtractError(
          Response.badRequest(
            body: await bodyToJson(message: 'Email некорректный', code: CodeAction.emailInvalid),
          ),
        );
      }

      // Валидация длины пароля: должен быть не менее 8 символов
      if (password.length < 8) {
        return ExtractError(
          Response.badRequest(
            body: await bodyToJson(
              message: 'Пароль должен быть не менее 8 символов',
              code: CodeAction.passwordInvalid,
            ),
          ),
        );
      }

      // Все проверки пройдены - возвращаем успешный результат
      return ExtractSuccess(email, password);
    } on Object catch (_) {
      // Обработка любых ошибок при парсинге или обработке запроса
      // (например, некорректный JSON, ошибка чтения потока и т.д.)
      return ExtractError(
        Response.internalServerError(
          body: await bodyToJson(
            message: 'Ошибка при обработке запроса пользователя',
            code: CodeAction.parseErrorInUserRequest,
          ),
        ),
      );
    }
  }

  /// Формирует JSON-строку для тела HTTP-ответа.
  ///
  /// Создает стандартизированный формат ответа с сообщением об ошибке
  /// и опциональным кодом действия.
  ///
  /// [message] - текстовое сообщение для клиента (обязательный параметр)
  /// [code] - код действия/ошибки для программной обработки (опциональный)
  ///
  /// Возвращает JSON-строку в формате: {"message": "...", "code": "..."}
  static Future<String> bodyToJson({required String message, String? code}) async {
    return jsonEncode({'message': message, 'code': code});
  }
}
