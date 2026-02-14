import 'dart:convert';

abstract class HandlerUtil {
  static Future<String> bodyToJson({required String message, String? code}) async {
    return jsonEncode({'message': message, 'code': code});
  }
}
