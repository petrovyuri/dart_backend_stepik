import 'package:http/http.dart' as http;

/// Тестирование Rate Limiter
void main() async {
  // URL для тестирования
  final url = Uri.parse('http://localhost:8080/health');
  print('--- Начинаем проверку Rate Limiter (Лимит: 10 запросов в минуту) ---');

  // Проверяем 15 запросов, выполняем цикл где
  // делаем запросы каждые 6 секунд
  for (var i = 1; i <= 15; i++) {
    try {
      final response = await http.get(url);
      // Проверяем статус код
      String status;
      if (response.statusCode == 429) {
        status = '🔴 429 Too Many Requests (Лимит превышен)';
      } else if (response.statusCode == 401) {
        status = '🟡 401 Unauthorized (Прошли через Rate Limiter, но нет токена)';
      } else {
        status = '🟢 ${response.statusCode} (Успешно)';
      }

      print('Запрос #$i: $status');
    } catch (e) {
      print('Запрос #$i: Ошибка соединения: $e');
    }
  }

  print('--- Проверка завершена ---');
}
