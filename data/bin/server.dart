import 'dart:io';

import 'package:data/di/di_container.dart';
import 'package:data/handlers/app_handlers.dart';
import 'package:data/logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

void main(List<String> args) async {
  // Создаём логгер и пишем стартовое сообщение.
  final logger = AppLogger()..info('Сервер запущен');

  // Создаём DI контейнер и загружаем конфигурацию.
  final diContainer = DiContainer(logger: logger);
  await diContainer.load();

  // Создаём обработчик приложения.
  final appHandler = AppHandler(diContainer);

  // Слушаем любой доступный интерфейс (удобно для контейнеров).
  final ip = InternetAddress.anyIPv4;

  // Конвейер с middleware логирования запросов и роутером.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(appHandler.handler);

  // Запускаем HTTP-сервер на сконфигурированном порту.
  final server = await serve(handler, ip, diContainer.config.port);
  print('Server listening on port ${server.port}');
}
