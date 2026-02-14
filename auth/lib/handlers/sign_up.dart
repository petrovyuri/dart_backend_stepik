part of 'app_handlers.dart';

Future<Response> _signUpHandler(Request request, DiContainer di) async {
  return Response.ok(jsonEncode({'message': 'User created successfully'}));
}
