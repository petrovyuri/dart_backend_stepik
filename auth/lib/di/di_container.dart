import 'package:auth/config/config.dart';
import 'package:auth/database/database.dart';
import 'package:auth/logger/logger.dart';
import 'package:auth/service/crypto_service.dart';
import 'package:auth/service/hash_service.dart';

// DI контейнер хранит общие зависимости приложения и отвечает за их инициализацию.
final class DiContainer {
  DiContainer({required this.logger});
  final AppLogger logger;

  /// Конфиг приложения.
  late final Config config;

  /// База данных приложения.
  late final AppDatabase database;

  /// Сервис для хэширования паролей.
  late final HashService hashService;

  /// Сервис для шифрования данных.
  late final CryptoService cryptoService;

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
      // Проверяем доступность базы данных.
      await AppDatabase.hasDbConnection(this);

      // Создаем сервис для хэширования паролей.
      hashService = HashService(config);
      // Создаем сервис для шифрования данных.
      cryptoService = CryptoService(config);
    } on Object catch (error, stackTrace) {
      logger.error('Ошибка при создании DI контейнера', error, stackTrace);
      rethrow;
    }
  }
}
