import 'dart:io';

import 'package:data/di/di_container.dart';
import 'package:data/logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Регистрируем маршруты для простых эндпоинтов.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

// Хэндлер главной страницы, возвращает базовый ответ.
Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

// Хэндлер, эхо-возврат части пути из параметра.
Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Создаём логгер и пишем стартовое сообщение.
  final logger = AppLogger()..info('Сервер запущен');

  // Создаём DI контейнер и загружаем конфигурацию.
  final diContainer = DiContainer(logger: logger);
  await diContainer.load();

  // Слушаем любой доступный интерфейс (удобно для контейнеров).
  final ip = InternetAddress.anyIPv4;

  // Конвейер с middleware логирования запросов и роутером.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  // Запускаем HTTP-сервер на сконфигурированном порту.
  final server = await serve(handler, ip, diContainer.config.port);
  print('Server listening on port ${server.port}');
}
