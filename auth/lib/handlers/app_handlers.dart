import 'dart:convert';

import 'package:auth/database/database.dart';
import 'package:auth/di/di_container.dart';
import 'package:auth/handlers/code_action.dart';
import 'package:auth/handlers/handler_utils.dart';
import 'package:auth/handlers/request_ext.dart';
import 'package:auth/middleware/jwt_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'health.dart';
part 'sign_up.dart';
part 'sign_in.dart';
part 'get_user.dart';
part 'update_user.dart';
part 'delete_user.dart';
part 'refresh_token.dart'; // Новое

/// Компонент верхнего уровня, который собирает и конфигурирует все HTTP‑маршруты приложения.
///
/// Через [`DiContainer`] внутрь можно передавать любые зависимости:
/// подключение к БД, репозитории, логгер и т.п.
final class AppHandler {
  /// Создаёт экземпляр `AppHandler`.
  ///
  /// - [di] — DI‑контейнер приложения, из которого хэндлеры получают зависимости.
  AppHandler({required this.di});

  /// DI‑контейнер приложения.
  final DiContainer di;

  /// Возвращает основной shelf‑хэндлер приложения.
  ///
  /// Здесь настраиваются:
  /// - маршруты (`Router`);
  /// - middleware (например, логирование запросов);
  /// - финальная сборка `Pipeline` → `Handler`.
  Handler get handler {
    // Создаем middleware для JWT авторизации
    final jwtMiddleware = JwtMiddleware(di);

    // Защищенные маршруты (требуют JWT)
    final protectedRouter = Router()
      ..get('/user', (request) => _getUserHandler(request, di))
      ..patch('/user', (request) => _updateUserHandler(request, di))
      ..delete('/user', (request) => _deleteUserHandler(request, di));

    // Оборачиваем защищенные маршруты в JWT middleware
    final protectedHandler = Pipeline().addMiddleware(jwtMiddleware.handler).addHandler(protectedRouter.call);

    // Регистрируем маршруты для простых эндпоинтов.
    //
    // GET /health — простой health‑check, реализован в части `health.dart`.
    // POST /sign-up — регистрация нового пользователя, реализован в части `sign_up.dart`.
    // POST /sign-in — авторизация пользователя, реализован в части `sign_in.dart`.
    // Защищенные маршруты (требуют JWT) — реализованы в части `get_user.dart`.
    final router = Router()
      ..get('/health', (request) => _healthHandler(request, di))
      ..post('/sign-up', (request) => _signUpHandler(request, di))
      ..post('/sign-in', (request) => _signInHandler(request, di))
      ..post('/refresh-token', (request) => _refreshTokenHandler(request, di)) // Новое
      // Защищенные маршруты (требуют JWT)
      ..mount('/auth', protectedHandler);

    // Оборачиваем хэндлеры в middleware:
    // - `logRequests()` — логирует каждый HTTP‑запрос и ответ.
    // В дальнейшем сюда можно добавлять авторизацию, CORS, обработку ошибок и др.
    return Pipeline().addMiddleware(logRequests()).addHandler(router.call);
  }
}
