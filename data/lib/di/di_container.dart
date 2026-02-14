import 'package:data/config/config.dart';
import 'package:data/database/database.dart' show AppDatabase;
import 'package:data/logger/logger.dart';
import 'package:data/service/jwt_service.dart';
import 'package:data/service/post_service.dart';

// DI контейнер хранит общие зависимости приложения и отвечает за их инициализацию.
final class DiContainer {
  DiContainer({required this.logger});
  final AppLogger logger;

  late final Config config;
  late final AppDatabase database;
  late final JwtService jwtService;
  late final PostService postService; // <--- НОВОЕ

  Future<void> load() async {
    try {
      // Создаем конфиг и подгружаем его из источника (env/файл).
      config = Config(logger: logger);
      await config.load();
      // Пробрасываем флаг окружения в логгер, чтобы он корректно форматировал вывод.
      logger.isStage = config.isStage;
      // Печатаем итоговые значения конфигурации в лог.
      config.showConfig();
      // Создаем базу данных.
      database = AppDatabase(this);
      // Тестовая проверка соединения с БД.
      // TODO: убрать после тестов
      await AppDatabase.hasDbConnection(this);
      // Создаем сервис для работы с JWT
      jwtService = JwtService(this);
      // Создаем сервис для работы с постами
      postService = PostService(this); // <--- НОВОЕ
    } on Object catch (error, stackTrace) {
      logger.error('Ошибка при создании DI контейнера', error, stackTrace);
      rethrow;
    }
  }
}
