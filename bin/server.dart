import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'article.dart';
import 'lib/controller.dart';

Response _rootHandler(Request req) {
  return Response.ok('Hello, World YES!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */

List<Article> articles = [];

Future<Response> _postArticleHandler(Request request) async {
  String body = await request.readAsString();

  try {
    Article article = articleFromJson(body);
    articles.add(article);
    return Response.ok(articleToJson(article));
  } catch (e) {
    return Response(400);
  }
}

Future<Response> _postDeleteArticleHandler(Request request) async {
  String body = await request.readAsString();

  try {
    return Response.ok('{"Action": "Delete", "status": "Success !"}');
  } catch (e) {
    print(e);
    return Response(400);
  }
}

Response _getArticlesHandler(Request request) {
  return Response.ok(articlesToJson(articles));
}

/* -------------------------------------------------------------------------- */

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final Controller ctrl = Controller();
  ctrl.connectSql();

// Configure routes.
  final router = Router()
    ..get('/', _rootHandler)
    ..get('/echo/<message>', _echoHandler)
    ..get('/articles', _getArticlesHandler)
    ..post('/articles', _postArticleHandler)
    ..delete('/articles', _postDeleteArticleHandler)
    ..get('/user', ctrl.getUserData)
    ..post('/userFilter', ctrl.getUserDataFilter)
    ..post('/postUserData', ctrl.postUserData)
    ..put('/putUpdateUser', ctrl.putUserData)
    ..delete('/deleteUser', ctrl.deleteUser);

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8081');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
