import 'package:data/database/database.dart';
import 'package:data/di/di_container.dart';
import 'package:drift/drift.dart';

/// Сервис для работы с постами
class PostService {
  PostService(this.di);

  /// Контейнер зависимостей
  final DiContainer di;

  /// Создает пост
  Future<int> createPost(int userId, String title, String content) async {
    try {
      // Создаем объект поста для вставки в базу данных
      final post = PostCompanion(authorId: Value(userId), title: Value(title), content: Value(content));

      // Вставляем пост в базу данных
      final postId = await di.database.into(di.database.post).insert(post);
      di.logger.info('Пост создан: id=$postId');

      // Возвращаем id созданного поста
      return postId;
    } on Object catch (e, stackTrace) {
      di.logger.error('Ошибка при создании поста в базе данных: $e', e, stackTrace);
      rethrow;
    }
  }
}
