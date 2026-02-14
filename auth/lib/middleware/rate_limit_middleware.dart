import 'dart:collection';

import 'package:auth/di/di_container.dart';
import 'package:auth/handlers/code_action.dart';
import 'package:auth/handlers/handler_utils.dart';
import 'package:shelf/shelf.dart';

/// Значения констант, которые могут быть изменены в конфиге
/// В продакшене лучше использовать переменные окружения
/// Время очистки устаревших записей
const _cleanupInterval = Duration(minutes: 5);

/// Окно времени - всегда 1 минута
const _windowDuration = Duration(minutes: 1);

/// Максимальное количество запросов в минуту
const _rateLimitPerMinute = 10;

/// Middleware для ограничения количества запросов (Rate Limiting)
///
/// Защищает API от брутфорс атак и злоупотребления
/// Лимит настраивается через переменную окружения RATE_LIMIT_PER_MINUTE
class RateLimitMiddleware {
  RateLimitMiddleware(this.di);

  final DiContainer di;

  /// Хранилище запросов по IP адресам
  /// Ключ: IP адрес
  /// Значение: Очередь временных меток запросов
  final Map<String, Queue<DateTime>> _requestHistory = {};

  /// Время последней очистки устаревших записей
  DateTime _lastCleanup = DateTime.now();

  /// Создает middleware handler
  Middleware get handler {
    return (Handler innerHandler) {
      return (Request request) async {
        // Получаем IP адрес клиента
        final clientIp = _getClientIp(request);

        // Проверяем лимит запросов
        if (!_checkRateLimit(clientIp)) {
          // Лимит превышен
          di.logger.info('Rate limit превышен для IP: $clientIp');

          return Response(
            429, // Too Many Requests
            body: await HandlerUtil.bodyToJson(
              message: 'Слишком много запросов. Попробуйте позже.',
              code: CodeAction.rateLimitExceeded,
            ),
          );
        }

        // Запрос разрешен, передаем дальше
        return await innerHandler(request);
      };
    };
  }

  /// Извлекает IP адрес клиента из запроса
  /// Учитывает прокси-серверы и load balancers
  String _getClientIp(Request request) {
    // Проверяем заголовки прокси
    final forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      // Берем первый IP из списка (реальный IP клиента)
      return forwardedFor.split(',').first.trim();
    }

    final realIp = request.headers['x-real-ip'];
    if (realIp != null && realIp.isNotEmpty) {
      return realIp;
    }

    // Если заголовков нет, используем дефолтное значение
    // В продакшене за прокси всегда будет заголовок X-Forwarded-For
    return 'unknown';
  }

  /// Проверяет, не превышен ли лимит запросов для данного IP
  /// Возвращает true, если запрос разрешен
  bool _checkRateLimit(String clientIp) {
    final now = DateTime.now();

    // Периодическая очистка устаревших записей
    if (now.difference(_lastCleanup) > _cleanupInterval) {
      _cleanupOldEntries();
      _lastCleanup = now;
    }

    // Получаем или создаем историю запросов для данного IP
    final history = _requestHistory.putIfAbsent(clientIp, () => Queue<DateTime>());

    // Удаляем запросы, которые вышли за пределы окна времени
    final cutoffTime = now.subtract(_windowDuration);
    while (history.isNotEmpty && history.first.isBefore(cutoffTime)) {
      history.removeFirst();
    }

    // Проверяем, не превышен ли лимит
    if (history.length >= _rateLimitPerMinute) {
      return false; // Лимит превышен
    }

    // Добавляем текущий запрос в историю
    history.add(now);
    return true; // Запрос разрешен
  }

  /// Очищает устаревшие записи из хранилища
  /// Удаляет IP адреса, у которых нет запросов в текущем окне
  void _cleanupOldEntries() {
    final now = DateTime.now();
    final cutoffTime = now.subtract(_windowDuration);

    // Удаляем IP адреса без активных запросов
    _requestHistory.removeWhere((ip, history) {
      // Удаляем старые запросы
      while (history.isNotEmpty && history.first.isBefore(cutoffTime)) {
        history.removeFirst();
      }
      // Если история пуста, удаляем запись
      return history.isEmpty;
    });

    di.logger.debug('Rate limit cleanup: ${_requestHistory.length} активных IP адресов');
  }
}
