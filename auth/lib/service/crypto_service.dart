import 'dart:convert';

import 'package:auth/config/config.dart';

/// Сервис для хэширования и шифрования данных
class CryptoService {
  CryptoService(this.config);

  final Config config;

  /// Шифрует данные (обратимо) - простое XOR шифрование с base64
  /// Используется для шифрования  в БД
  String encryptData(String data) {
    final dataBytes = utf8.encode(data);
    final saltBytes = utf8.encode(config.salt);

    // XOR шифрование
    final encrypted = <int>[];
    for (var i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ saltBytes[i % saltBytes.length]);
    }

    return base64.encode(encrypted);
  }

  /// Расшифровывает данные
  String decryptData(String encryptedData) {
    final encryptedBytes = base64.decode(encryptedData);
    final saltBytes = utf8.encode(config.salt);

    // XOR дешифрование (XOR обратим: A XOR B XOR B = A)
    final decrypted = <int>[];
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ saltBytes[i % saltBytes.length]);
    }

    return utf8.decode(decrypted);
  }
}
