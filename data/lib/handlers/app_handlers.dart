import 'dart:convert';

import 'package:data/di/di_container.dart';
import 'package:data/handlers/code_action.dart';
import 'package:data/handlers/handler_utils.dart';
import 'package:data/middleware/jwt_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'health_check.dart';
part 'create_post.dart';
part 'get_post.dart'; // <--- НОВОЕ

class AppHandler {
  AppHandler(DiContainer di) : _di = di;

  final DiContainer _di;

  // Геттер для получения обработчика
  Handler get handler {
    final jwtMiddleware = JwtMiddleware(_di);

    // Основной роутер
    final mainRouter = Router()
      ..get('/health', (request) => _healthCheckHandler(request, _di))
      ..post('/posts', (request) => _createPostHandler(request, _di))
      // <id> - это параметр, который будет передаваться в функцию _getPostHandler
      ..get('/posts/<id>', (request, id) => _getPostHandler(request, _di, id)); // <--- НОВОЕ

    // Основной pipeline с JWT
    final mainPipeline = Pipeline().addMiddleware(jwtMiddleware.handler).addHandler(mainRouter.call);

    return mainPipeline;
  }
}
