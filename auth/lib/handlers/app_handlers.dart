import 'package:auth/database/database.dart';
import 'package:auth/di/di_container.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'health.dart';

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
    final router = Router()..get('/health', (request) => _healthHandler(request, di));

    // Оборачиваем хэндлеры в middleware:
    // - `logRequests()` — логирует каждый HTTP‑запрос и ответ.
    // В дальнейшем сюда можно добавлять авторизацию, CORS, обработку ошибок и др.
    return Pipeline().addMiddleware(logRequests()).addHandler(router.call);
  }
}
