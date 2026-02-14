import 'dart:convert';

import 'package:auth/config/config.dart';
import 'package:crypto/crypto.dart';

/// Сервис для хэширования и шифрования данных
class HashService {
  HashService(this.config);

  final Config config;

  /// Хэширует пароль Необратимо с использованием PBKDF2-подобного подхода
  String hashPassword(String password) {
    final saltBytes = utf8.encode(config.salt);
    final passwordBytes = utf8.encode(password);

    // Комбинируем пароль и соль
    final combined = [...passwordBytes, ...saltBytes];

    // Применяем SHA-256 несколько раз для увеличения стойкости
    var hash = sha256.convert(combined);
    for (var i = 0; i < 10000; i++) {
      hash = sha256.convert([...hash.bytes, ...saltBytes]);
    }

    return base64.encode(hash.bytes);
  }

  /// Проверяет, соответствует ли пароль хэшу
  bool verifyData(String password, String hashedPassword) {
    final hashed = hashPassword(password);
    return hashed == hashedPassword;
  }
}
