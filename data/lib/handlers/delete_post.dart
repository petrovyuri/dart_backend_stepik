part of 'app_handlers.dart';

Future<Response> _deletePostHandler(Request request, DiContainer di, String postId) async {
  try {
    final userId = request.userId;
    if (userId == null) {
      return Response.unauthorized(
        await HandlerUtil.bodyToJson(
          message: 'Ошибка авторизации',
          code: CodeAction.authorizationTokenProcessingError,
        ),
      );
    }
    await di.postService.deletePost(int.parse(postId), userId);
    return Response.ok(await HandlerUtil.bodyToJson(message: 'Пост удален', code: CodeAction.postDeleted));
  } on Object catch (e, stackTrace) {
    di.logger.error('Ошибка при удалении поста: $e', e, stackTrace);
    return Response.internalServerError(
      body: await HandlerUtil.bodyToJson(
        message: 'Ошибка при удалении поста',
        code: CodeAction.deletePostError,
      ),
    );
  }
}
