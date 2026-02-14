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

  /// Хост базы данных.
  late final String dbHost;

  /// Имя базы данных.
  late final String dbName;

  /// Пользователь базы данных.
  late final String dbUser;

  /// Пароль базы данных.
  late final String dbPassword;

  /// Порт базы данных.
  late final int dbPort;

  /// Секрет для парсинга JWT токена
  late final String JWTSecret;

  /// Секрет для межсервисных запросов
  late final String internalSecret;

  /// Хост Redis
  late final String redisHost;

  /// Порт Redis
  late final int redisPort;

  /// Загружает конфигурацию из переменных окружения и логирует результат.
  Future<void> load() async {
    logger.info('Загрузка конфигурации');
    try {
      // Берём значения из окружения и сохраняем их в поля класса.
      port = int.parse(_getEnv('PORT'));
      isStage = _getEnv('IS_STAGE') == 'true';
      dbHost = _getEnv('DB_HOST');
      dbName = _getEnv('DB_NAME');
      dbUser = _getEnv('DB_USER');
      dbPassword = _getEnv('DB_PASSWORD');
      dbPort = int.parse(_getEnv('DB_PORT'));
      JWTSecret = _getEnv('JWT_SECRET');
      internalSecret = _getEnv('INTERNAL_SECRET');
      redisHost = _getEnv('REDIS_HOST');
      redisPort = int.parse(_getEnv('REDIS_PORT'));
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
        ..debug('Статус: stage')
        ..debug('DB Host: $dbHost')
        ..debug('DB Name: $dbName')
        ..debug('DB User: $dbUser')
        ..debug('DB Password: $dbPassword')
        ..debug('DB Port: $dbPort')
        ..debug('JWT Secret: $JWTSecret')
        ..debug('Internal Secret: $internalSecret')
        ..debug('Redis Host: $redisHost')
        ..debug('Redis Port: $redisPort');
    }
  }
}
