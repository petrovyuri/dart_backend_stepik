import 'dart:io';

/// Префикс имени для всех логов приложения аутентификации.
const String _name = '[DATA]';

/// Логгер для сервера.
/// Предоставляет методы для логирования информационных сообщений, ошибок и отладочной информации.
final class AppLogger {
  /// Флаг, определяющий, включен ли режим отладки (stage).
  /// Когда `true`, метод [debug] будет выводить отладочные сообщения.
  bool _isStage = false;

  /// Логирует информационное сообщение.
  /// Выводит сообщение в стандартный поток вывода с меткой INFO.
  ///
  /// [message] - текст информационного сообщения для логирования.
  void info(String message) {
    stdout.writeln('${DateTime.now()}: $_name:[INFO] $message');
  }

  /// Логирует сообщение об ошибке.
  /// Выводит сообщение в стандартный поток ошибок с меткой ERROR.
  ///
  /// [message] - описание ошибки.
  /// [error] - объект ошибки.
  /// [stackTrace] - трассировка стека (может быть null).
  void error(String message, Object error, StackTrace? stackTrace) {
    stderr.writeln('${DateTime.now()}: $_name:[ERROR] $message, $error, $stackTrace');
  }

  /// Логирует отладочное сообщение.
  /// Сообщение выводится только если включен режим отладки через сеттер [isStage].
  /// Выводит сообщение в стандартный поток вывода с меткой DEBUG.
  ///
  /// [message] - текст отладочного сообщения для логирования.
  void debug(String message) {
    if (_isStage) {
      stdout.writeln('${DateTime.now()}: $_name:[DEBUG] $message');
    }
  }

  /// Устанавливает режим отладки (stage) через сеттер.
  /// Когда [isStage] равен `true`, метод [debug] будет выводить отладочные сообщения.
  set isStage(bool isStage) {
    _isStage = isStage;
  }
}
