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

  /// Получаем пост по id
  Future<PostData?> getPost(int postId, int userId) async {
    try {
      di.logger.info('Получение поста: postId=$postId, userId=$userId');
      // Создаем запрос на получение поста
      final query = di.database.select(di.database.post)
        ..where((t) => t.id.equals(postId) & t.authorId.equals(userId))
        ..limit(1);
      // Выполняем запрос
      final posts = await query.get();
      // Если пост не найден
      if (posts.isEmpty) {
        // Возвращаем null
        di.logger.info('Пост не найден: postId=$postId, userId=$userId');
        return null;
      }
      di.logger.info('Получен пост: postId=$postId, userId=$userId');
      // Возвращаем пост
      return posts.first;
    } on Object catch (e, stackTrace) {
      di.logger.error('Ошибка при получении поста из базе данных: $e', e, stackTrace);
      rethrow;
    }
  }
}
