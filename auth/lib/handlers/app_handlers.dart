import 'dart:convert';

import 'package:auth/database/database.dart';
import 'package:auth/di/di_container.dart';
import 'package:auth/handlers/code_action.dart';
import 'package:auth/handlers/handler_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'health.dart';
part 'sign_up.dart';
part 'sign_in.dart';

/// <--- Новый part для sign_in.dart

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
    // Регистрируем маршруты для простых эндпоинтов.
    //
    // GET /health — простой health‑check, реализован в части `health.dart`.
    // POST /sign-up — регистрация нового пользователя, реализован в части `sign_up.dart`.
    final router = Router()
      ..get('/health', (request) => _healthHandler(request, di))
      ..post('/sign-up', (request) => _signUpHandler(request, di))
      ..post('/sign-in', (request) => _signInHandler(request, di));

    /// <--- Новый маршрут

    // Оборачиваем хэндлеры в middleware:
    // - `logRequests()` — логирует каждый HTTP‑запрос и ответ.
    // В дальнейшем сюда можно добавлять авторизацию, CORS, обработку ошибок и др.
    return Pipeline().addMiddleware(logRequests()).addHandler(router.call);
  }
}
