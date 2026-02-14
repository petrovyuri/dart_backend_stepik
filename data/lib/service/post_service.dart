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

      // *** НОВОЕ ***
      // Инвалидируем кеш постов пользователя, так как добавился новый пост
      await di.cacheService.invalidateUserPostsCache(userId);
      di.logger.info('Кеш постов пользователя инвалидирован после создания поста: userId=$userId');
      // *** КОНЕЦ НОВОГО ***

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

  /// Получаем список всех постов пользователя с пагинацией
  Future<List<PostData>> getPosts(int userId, {int limit = 10, int offset = 0}) async {
    try {
      // *** НОВОЕ ***
      // Сначала пытаемся получить из кеша
      final cachedPosts = await di.cacheService.getCachedPosts(userId, limit, offset);
      if (cachedPosts != null) {
        di.logger.info('Посты получены из кеша Redis: userId=$userId, limit=$limit, offset=$offset');
        return cachedPosts;
      }
      // *** КОНЕЦ НОВОГО ***
      di.logger.info('Получение списка постов: userId=$userId, limit=$limit, offset=$offset');

      // Создаем запрос: выбираем посты юзера, сортируем по ID (новые сверху) и ограничиваем выборку
      final query = di.database.select(di.database.post)
        ..where((t) => t.authorId.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset);

      final posts = await query.get();

      // *** НОВОЕ ***
      // Сохраняем посты в кеш после получения из БД
      await di.cacheService.cachePosts(userId, limit, offset, posts);
      di.logger.info('Посты сохранены в кеш Redis: userId=$userId, limit=$limit, offset=$offset');
      // *** КОНЕЦ НОВОГО ***

      return posts;
    } on Object catch (e, stackTrace) {
      di.logger.error('Ошибка при получении списка постов из БД: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Удаляем пост
  Future<void> deletePost(int postId, int userId) async {
    try {
      // Создаем запрос на удаление поста
      final query = di.database.delete(di.database.post)
        ..where((t) => t.id.equals(postId) & t.authorId.equals(userId));
      // Выполняем запрос
      await query.go();
      di.logger.info('Пост удален: postId=$postId, userId=$userId');
      // *** НОВОЕ ***
      // Инвалидируем кеш постов пользователя, так как пост был удален
      await di.cacheService.invalidateUserPostsCache(userId);
      di.logger.info('Кеш постов пользователя инвалидирован после удаления поста: userId=$userId');
      // *** КОНЕЦ НОВОГО ***
    } on Object catch (e, stackTrace) {
      di.logger.error('Ошибка при удалении поста из базе данных: $e', e, stackTrace);
      rethrow;
    }
  }
}
