import 'dart:io';

import 'package:auth/di/di_container.dart';
import 'package:auth/handlers/app_handlers.dart';
import 'package:auth/logger/logger.dart';
import 'package:shelf/shelf_io.dart';

void main(List<String> args) async {
  // Создаём логгер и пишем стартовое сообщение.
  final logger = AppLogger()..info('Сервер запущен');

  // Создаём DI контейнер и загружаем конфигурацию.
  final diContainer = DiContainer(logger: logger);
  await diContainer.load();

  // Создаём хэндлер приложения.
  final appHandler = AppHandler(di: diContainer);

  // Слушаем любой доступный интерфейс (удобно для контейнеров).
  final ip = InternetAddress.anyIPv4;

  // Запускаем HTTP-сервер на сконфигурированном порту.
  final server = await serve(appHandler.handler, ip, diContainer.config.port);
  logger.info('Сервер запущен на порту ${server.port}');
}
