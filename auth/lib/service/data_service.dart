import 'package:auth/di/di_container.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Сервис для взаимодействия с API сервиса data
class DataService {
  /// Конструктор
  DataService(this.di);
  final DiContainer di;

  /// Удаляет все посты пользователя через API сервиса data
  Future<void> deleteUserPostsViaApi(int userId) async {
    try {
      // Составление URL для запроса
      final url = Uri.parse(
        'http://${di.config.dataHost}:${di.config.dataPort}${di.config.dataRequest}$userId',
      );
      di.logger.info('Вызов API для удаления постов пользователя $userId: $url');

      // Выполнение DELETE запроса
      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-internal-secret': di.config.internalSecret, // Секрет для валидации межсервисных запросов
            },
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Таймаут при вызове API сервиса data');
            },
          );

      // Обработка ответа
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        di.logger.info('Посты пользователя $userId удалены через API: ${responseBody['message']}');
      } else {
        di.logger.info('API сервиса data вернул статус ${response.statusCode}: ${response.body}');
      }
    } on Object catch (e, stackTrace) {
      // Логирование ошибки
      di.logger.error('Ошибка при вызове API для удаления постов пользователя $userId: $e', e, stackTrace);
      rethrow;
    }
  }
}
