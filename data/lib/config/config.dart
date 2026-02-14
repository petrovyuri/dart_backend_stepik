import 'dart:io';

import 'package:data/logger/logger.dart';

/// Отвечает за загрузку и хранение конфигурации приложения.
final class Config {
  Config({required this.logger});

  /// Логгер, передаётся извне для единообразного логирования.
  final AppLogger logger;

  /// Порт, на котором поднимется HTTP‑сервер.
  late final int port;

  /// Флаг, указывающий на работу в stage-режиме (расширенное логирование).
  late final bool isStage;

  /// Загружает конфигурацию из переменных окружения и логирует результат.
  Future<void> load() async {
    logger.info('Загрузка конфигурации');
    try {
      // Берём значения из окружения и сохраняем их в поля класса.
      port = int.parse(_getEnv('PORT'));
      isStage = _getEnv('IS_STAGE') == 'true';
    } catch (e) {
      // Дублируем ошибку в лог и пробрасываем наружу, чтобы остановить запуск.
      logger.error('Ошибка при загрузке конфигурации', e, StackTrace.current);
      throw Exception('Ошибка при загрузке конфигурации');
    }
  }

  /// Возвращает значение переменной окружения или кидает исключение,
  /// если её нет. Так гарантируем обязательность настроек.
  String _getEnv(String name) {
    final value = Platform.environment[name];
    if (value == null) {
      throw Exception('Переменная окружения $name не установлена');
    }
    return value;
  }

  /// Показывает текущую конфигурацию в stage-режиме для отладки.
  void showConfig() {
    if (isStage) {
      logger
        ..debug('Конфигурация:')
        ..debug('Порт: $port')
        ..debug('Статус: stage');
    }
  }
}
