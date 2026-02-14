import 'package:drift/drift.dart';

class Post extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get authorId => integer()(); // Foreign key к User
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get content => text()();
}
