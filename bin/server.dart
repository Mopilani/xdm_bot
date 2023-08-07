// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:dart_telegram_bot/dart_telegram_bot.dart';
import 'package:dart_telegram_bot/telegram_entities.dart' as telegram_entities;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'bot_command.dart';
import 'endpoints.dart';
import 'io_functions.dart';
import 'lesson.dart';
import 'server_todo.dart';

var conf;
void main(List<String> args) async {
  Map<String, Function(Request)> supportedCommands = {
    'commands': commands,
    'authors': getAuthors,
    'greating': greating,
    'lessons': monthLessons,
    'all-lessons': allLessons,
    'faqs': faqEndpoint,
  };

  var confFile = File('srv.cfg');
  conf = json.decode(await confFile.readAsString());

  Bot(
    // Insert your bot token here
    token: conf['tbot_token'],
    // Once the bot is ready this function will be called
    // You can start the bot here
    onReady: (bot) => bot.start(clean: true),
    // Register a new callback for new updates
    allowedUpdates: [...telegram_entities.UpdateType.values.values],
  ).onUpdate((bot, update) async {
    var msgTxt = update.message?.text;
    if (msgTxt != null) {
      print(update.message?.text);
      // if (msgTxt.startsWith('!')) {
      //   var segs = msgTxt.split(':');
      //   var command = segs[0];
      //   var arg = segs[1];
      // } else
      // print(msgTxt.toLowerCase().startsWith('l:'));
      if (msgTxt.toLowerCase().startsWith('l:')) {
        var segs = msgTxt.split(':');
        var authorUsername = segs[1];
        var lessonId = segs[2];
        print('init req');
        var req = Request('GET', Uri.parse('http://localhost.com/'), context: {
          'shelf_router/params': {
            'lessonName': Lesson.getKeyByIdFrom(authorUsername, lessonId)
          }
        });
        print('req: ${req.params}');
        Response res = getLesson(req);
        print('res.statusCode: ${res.statusCode}');

        bot.sendMessage(
          telegram_entities.ChatID(update.message!.chat.id),
          (await res.readAsString()).toString(),
        );
      } else {
        if (supportedCommands[msgTxt] != null) {
          var req = Request('GET', Uri.parse('http://localhost.com/'));
          print('${supportedCommands[msgTxt]}');
          Response res = await supportedCommands[msgTxt]!.call(req);
          await bot.sendMessage(
            telegram_entities.ChatID(update.message!.chat.id),
            (await res.readAsString()).toString(),
          );
        }
      }
    }
    // Send a message to the update chat with the received message
  });

  var _lessonsFile = File(lessonsFile);
  if (!_lessonsFile.existsSync()) _lessonsFile.createSync();
  var _authorsFile = File(authorsFile);
  if (!_authorsFile.existsSync()) _authorsFile.createSync();
  await loadAuthors();
  await loadLessons();
  await loadfreqAskedQues();
  await ServerTODO.loadTasks();
  BotCommand.loadCommands();

  // Use any available host or container IP (usually `0.0.0.0`).
  // final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8185');
  final server = await serve(handler, '0.0.0.0', port);
  print('Server listening on port ${server.port}');
}
