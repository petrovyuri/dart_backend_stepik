import 'dart:convert';

import 'package:data/database/database.dart';
import 'package:data/di/di_container.dart';
import 'package:redis_dart_client/redis_dart_client.dart';

/// Сервис для работы с Redis кешем
class CacheService {
  CacheService(this.di);
  final DiContainer di;

  RedisClient? _redisClient;
  bool _isConnected = false;

  /// Проверка состояния подключения к Redis
  bool get isConnected => _isConnected;

  /// Подключение к Redis
  Future<void> connect() async {
    try {
      _redisClient = RedisClient(host: di.config.redisHost, port: di.config.redisPort);
      await _redisClient!.connect();
      // Проверяем подключение, выполняя простую команду GET на несуществующий ключ
      await _redisClient!.get('__connection_test__');
      _isConnected = true;
      di.logger.info('Подключение к Redis установлено: ${di.config.redisHost}:${di.config.redisPort}');
    } on Object catch (e, s) {
      di.logger.error('Ошибка подключения к Redis: $e', e, s);
      _isConnected = false;
      _redisClient = null;
      // Не пробрасываем ошибку, чтобы приложение могло работать без Redis
    }
  }

  /// Закрытие соединения с Redis
  Future<void> close() async {
    if (_redisClient != null && _isConnected) {
      try {
        _redisClient = null;
        _isConnected = false;
        di.logger.info('Соединение с Redis закрыто');
      } on Object catch (e, s) {
        di.logger.error('Ошибка при закрытии соединения с Redis: $e', e, s);
      }
    }
  }

  /// Проверка доступности Redis с помощью команды PING
  Future<bool> ping() async {
    if (!_isConnected || _redisClient == null) {
      return false;
    }

    try {
      // Выполняем простую команду для проверки соединения
      await _redisClient!.get('__health_check__');
      return true;
    } on Object catch (e, s) {
      di.logger.error('Ошибка при ping Redis: $e', e, s);
      return false;
    }
  }

  /// Генерация ключа кеша для списка постов
  String _getPostsCacheKey(int userId, int limit, int offset) {
    return 'posts:user:$userId:limit:$limit:offset:$offset';
  }

  /// Генерация ключа для инвалидации всех постов пользователя
  String _getUserPostsPattern(int userId) {
    return 'posts:user:$userId:*';
  }

  /// Получение постов из кеша
  Future<List<PostData>?> getCachedPosts(int userId, int limit, int offset) async {
    if (!_isConnected || _redisClient == null) {
      di.logger.info('Redis не подключен, пропускаем кеш');
      return null;
    }

    try {
      final key = _getPostsCacheKey(userId, limit, offset);
      di.logger.info('Попытка получить из кеша ключ: $key');
      final cachedData = await _redisClient!.get(key);

      if (cachedData == null || cachedData.isEmpty) {
        di.logger.info('Кеш пуст для ключа: $key');
        return null;
      }

      final jsonData = jsonDecode(cachedData) as List<dynamic>;
      final posts = jsonData.map((json) => _postFromJson(json as Map<String, dynamic>)).toList();

      di.logger.info(
        'Посты получены из кеша: userId=$userId, limit=$limit, offset=$offset, количество: ${posts.length}',
      );
      return posts;
    } on Object catch (e, s) {
      di.logger.error('Ошибка при получении постов из кеша: $e', e, s);
      return null;
    }
  }

  /// Сохранение постов в кеш
  Future<void> cachePosts(int userId, int limit, int offset, List<PostData> posts) async {
    if (!_isConnected || _redisClient == null) {
      di.logger.info('Redis не подключен, пропускаем сохранение в кеш');
      return;
    }

    try {
      final key = _getPostsCacheKey(userId, limit, offset);
      final jsonData = posts.map((post) => _postToJson(post)).toList();
      final jsonString = jsonEncode(jsonData);

      di.logger.info('Сохранение в кеш ключ: $key, размер данных: ${jsonString.length} байт');

      // Кешируем на 5 минут (setex: key, value, seconds)
      await _redisClient!.setex(key, jsonString, 300);

      // Проверяем, что данные действительно сохранились
      final verify = await _redisClient!.get(key);
      if (verify != null && verify.isNotEmpty) {
        di.logger.info(
          'Посты сохранены в кеш: userId=$userId, limit=$limit, offset=$offset, количество: ${posts.length}',
        );
      } else {
        di.logger.info('Данные не сохранились в кеш после записи: $key');
      }
    } on Object catch (e, s) {
      di.logger.error('Ошибка при сохранении постов в кеш: $e', e, s);
      // Не пробрасываем ошибку, чтобы не ломать основной функционал
    }
  }

  /// Инвалидация кеша всех постов пользователя
  Future<void> invalidateUserPostsCache(int userId) async {
    if (!_isConnected || _redisClient == null) {
      return;
    }

    try {
      final pattern = _getUserPostsPattern(userId);
      // Получаем все ключи, соответствующие паттерну
      final keys = await _redisClient!.keys(pattern);

      if (keys.isNotEmpty) {
        // Удаляем все найденные ключи
        await _redisClient!.delete(keys);
        di.logger.info(
          'Кеш постов пользователя инвалидирован: userId=$userId, удалено ключей: ${keys.length}',
        );
      }
    } catch (e, s) {
      di.logger.error('Ошибка при инвалидации кеша постов: $e', e, s);
      // Не пробрасываем ошибку, чтобы не ломать основной функционал
    }
  }

  /// Преобразование PostData в JSON
  Map<String, dynamic> _postToJson(PostData post) {
    return {'id': post.id, 'authorId': post.authorId, 'title': post.title, 'content': post.content};
  }

  /// Преобразование JSON в PostData
  PostData _postFromJson(Map<String, dynamic> json) {
    return PostData(
      id: json['id'] as int,
      authorId: json['authorId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
