import 'package:auth/database/database.dart';
import 'package:auth/di/di_container.dart';
import 'package:drift/drift.dart';

/// Сервис для работы с пользователями.
/// [di] - DI контейнер.
class UserService {
  /// Конструктор сервиса.
  /// [di] - DI контейнер.
  UserService(this.di);

  /// DI контейнер.
  final DiContainer di;

  /// Создает нового пользователя в базе данных.
  /// [email] - email пользователя
  /// [password] - пароль пользователя
  /// Возвращает идентификатор нового пользователя или выбрасывает ошибку
  Future<int> createUser(String email, String password) async {
    // Хэшируем пароль (необратимо)
    final hashedPassword = di.hashService.hashPassword(password);
    // Шифруем email (обратимо)
    final encryptedEmail = di.cryptoService.encryptData(email);
    // Создаем обьект пользователя, для вставки в БД
    final userCompanion = UsersCompanion(email: Value(encryptedEmail), password: Value(hashedPassword));
    try {
      final database = di.database;
      // Вызываем операцию вставки в БД
      final id = await database.into(database.users).insert(userCompanion);
      di.logger.info('Пользователь создан: $id');
      return id;
    } on Object catch (e, stackTrace) {
      di.logger.error('Ошибка при создании пользователя: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Получает пользователя по email из базы данных.
  /// [email] - email пользователя
  /// Возвращает пользователя или null, если пользователь не найден
  Future<User?> getUserByEmail(String email) async {
    // Шифруем email, так как в базе данных он хранится в зашифрованном виде
    final encryptedEmail = di.cryptoService.encryptData(email);
    try {
      // Вызываем операцию выборки из БД
      // Используем оператор .. для цепочки операций
      // ..where((user) => user.email.equals(encryptedEmail)) - добавляем условие выборки
      // getSingleOrNull() - возвращает первый результат или null, если результатов нет
      final user = await (di.database.select(
        di.database.users,
      )..where((user) => user.email.equals(encryptedEmail))).getSingleOrNull();
      return user;
    } catch (e, stackTrace) {
      di.logger.error('Ошибка при получении пользователя: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Получает пользователя по id из базы данных.
  /// [id] - id пользователя
  /// Возвращает пользователя или null, если пользователь не найден
  Future<User?> getUserById(int id) async {
    try {
      final user = await (di.database.select(
        di.database.users,
      )..where((user) => user.id.equals(id))).getSingleOrNull();
      return user;
    } catch (e, stackTrace) {
      di.logger.error('Ошибка при получении пользователя: $e', e, stackTrace);
      rethrow;
    }
  }
}
