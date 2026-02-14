import 'package:shelf/shelf.dart';

/// Расширение для удобного доступа к userId и payload токена из контекста запроса
extension RequestExt on Request {
  /// Получает userId из контекста запроса
  int? get userId => context['userId'] as int?;

  /// Получает payload токена из контекста запроса
  Map<String, dynamic>? get tokenPayload => context['tokenPayload'] as Map<String, dynamic>?;
}
