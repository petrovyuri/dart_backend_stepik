import 'package:data/database/models/post.dart';
import 'package:data/di/di_container.dart';
import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

@DriftDatabase(tables: [Post])
/// Базовый Drift‑репозиторий приложения: создает подключение и хранит таблицы.
class AppDatabase extends _$AppDatabase {
  /// Конструктор базы данных.
  ///
  /// [di] - DI контейнер.
  /// [executor] - QueryExecutor, если передан, то используется для подключения к базе данных.
  AppDatabase(DiContainer di, [QueryExecutor? executor]) : super(executor ?? _openConnection(di));

  /// Версия схемы базы данных.
  @override
  int get schemaVersion => 1;

  /// Поднимает подключение к Postgres, используя конфиг и передавая его Drift.
  static QueryExecutor _openConnection(DiContainer di) {
    // Настройки подключения к базе данных.
    final connectionSettings = pg.ConnectionSettings(sslMode: pg.SslMode.disable);

    // Создание подключения к базе данных.
    final database = PgDatabase(
      // Endpoint - адрес базы данных.
      endpoint: pg.Endpoint(
        host: di.config.dbHost,
        database: di.config.dbName,
        username: di.config.dbUser,
        password: di.config.dbPassword,
        port: di.config.dbPort,
      ),
      settings: connectionSettings,
    );
    di.logger.info('Успешное создание подключения к базе данных');
    return database;
  }

  /// Проверяет доступность базы данных.
  ///
  /// [di] - DI контейнер.
  ///
  /// Возвращает `true`, если база данных доступна, иначе `false`.
  static Future<bool> hasDbConnection(DiContainer di) async {
    try {
      await di.database.customSelect('select 1').getSingle();
      di.logger.info('База данных доступна');
      return true;
    } catch (e, st) {
      di.logger.error('База данных недоступна', e, st);
      return false;
    }
  }
}
