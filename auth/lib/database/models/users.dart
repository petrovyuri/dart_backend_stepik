import 'package:drift/drift.dart';

/// Модель пользователя в базе данных.
///
/// [id] - идентификатор пользователя (автоинкрементируемый).
/// [email] - email пользователя (уникальный).
/// [password] - пароль пользователя (минимум 8 символов, максимум 200 символов).
class Users extends Table {
  /// Идентификатор пользователя.
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text().withLength(min: 8, max: 200)();
}
