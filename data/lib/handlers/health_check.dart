part of 'app_handlers.dart';

/// Обработчик для проверки здоровья сервиса
Future<Response> _healthCheckHandler(Request request, DiContainer di) async {
  try {
    // Проверяем подключение к базе данных и Redis
    final dbHealthy = await _checkDatabaseHealth(di);

    final status = (dbHealthy) ? 'healthy' : 'unhealthy';
    final statusCode = (dbHealthy) ? 200 : 503;

    final responseBody = jsonEncode({
      'status': status,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'service': 'data',
      'version': '1.0.0',
      'checks': {'database': dbHealthy ? 'up' : 'down'},
    });

    return Response(statusCode, body: responseBody);
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при проверке здоровья: $e', e, stackTrace);
    return Response.internalServerError(
      body: jsonEncode({
        'status': 'error',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'service': 'data',
      }),
    );
  }
}

/// Проверяет доступность базы данных
Future<bool> _checkDatabaseHealth(DiContainer di) async {
  try {
    // Простой запрос для проверки подключения
    await di.database.customSelect('SELECT 1').get();
    return true;
  } on Object catch (e) {
    di.logger.info('База данных недоступна: $e');
    return false;
  }
}
