import 'dart:io';

import 'package:auth/logger/logger.dart';

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

  /// Соль для хэширования паролей.
  late final String salt;

  /// Секретный ключ для JWT.
  late final String jwtSecret;

  /// Время жизни access токена в минутах.
  late final int jwtAccessExp;

  /// Время жизни refresh токена в минутах.
  late final int jwtRefreshExp;

  /// URL для отправки уведомления о удалении пользователя
  /// В микросервис data
  late final String dataRequest;

  /// Порт микросервиса data
  late final int dataPort;

  /// Секрет для валидации межсервисных запросов
  late final String internalSecret;

  /// Хост микросервиса data
  late final String dataHost;

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
      salt = _getEnv('SALT');
      jwtSecret = _getEnv('JWT_SECRET');
      jwtAccessExp = int.parse(_getEnv('JWT_ACCESS_EXP'));
      jwtRefreshExp = int.parse(_getEnv('JWT_REFRESH_EXP'));
      dataRequest = _getEnv('DATA_REQUEST');
      dataPort = int.parse(_getEnv('DATA_PORT'));
      internalSecret = _getEnv('INTERNAL_SECRET');
      dataHost = _getEnv('DATA_HOST');
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
        ..debug('Хост базы данных: $dbHost')
        ..debug('Имя базы данных: $dbName')
        ..debug('Пользователь базы данных: $dbUser')
        ..debug('Пароль базы данных: $dbPassword')
        ..debug('Порт базы данных: $dbPort')
        ..debug('Соль для хэширования паролей: $salt')
        ..debug('Секретный ключ для JWT: $jwtSecret')
        ..debug('Время жизни access токена: $jwtAccessExp')
        ..debug('Время жизни refresh токена: $jwtRefreshExp')
        ..debug('URL для отправки уведомления о удалении пользователя: $dataRequest')
        ..debug('Порт микросервиса data: $dataPort')
        ..debug('Секрет для валидации межсервисных запросов: $internalSecret');
    }
  }
}
