import 'package:data/config/config.dart';
import 'package:data/logger/logger.dart';

// DI контейнер хранит общие зависимости приложения и отвечает за их инициализацию.
final class DiContainer {
  DiContainer({required this.logger});
  final AppLogger logger;

  late final Config config;

  Future<void> load() async {
    try {
      // Создаем конфиг и подгружаем его из источника (env/файл).
      config = Config(logger: logger);
      await config.load();
      // Пробрасываем флаг окружения в логгер, чтобы он корректно форматировал вывод.
      logger.isStage = config.isStage;
      // Печатаем итоговые значения конфигурации в лог.
      config.showConfig();
    } on Object catch (error, stackTrace) {
      logger.error('Ошибка при создании DI контейнера', error, stackTrace);
      rethrow;
    }
  }
}
