part of 'app_handlers.dart';

/// Health‑эндпоинт сервиса авторизации.
///
/// Проверяет доступность базы данных и возвращает JSON‑ответ
/// со статусом сервера / базы.
Future<Response> _healthHandler(Request request, DiContainer di) async {
  try {
    // Проверяем соединение с базой данных через Drift/Postgres.
    final isDbConnected = await AppDatabase.hasDbConnection(di);

    // Если база недоступна — сразу отвечаем 503 (Service Unavailable)
    // и пишем об этом в теле ответа.
    if (!isDbConnected) {
      return Response(503, body: 'База данных недоступна', headers: {'Content-Type': 'application/json'});
    }

    // Если всё ок — возвращаем 200 и сообщение о том, что сервер и БД доступны.
    return Response.ok(
      'Сервер доступен, база данных доступна',
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    // На любой непойманной ошибке также возвращаем 500 (Internal Server Error)
    // чтобы внешний оркестратор мог понять, что сервис не здоров.
    return Response.internalServerError(
      body: 'Ошибка при проверке доступности сервера: $e',
      headers: {'Content-Type': 'application/json'},
    );
  }
}
