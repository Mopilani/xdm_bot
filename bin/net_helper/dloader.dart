import '../bot_command.dart';
import '../functions.dart';

import 'package:http/http.dart' as http;

class Dloader {
  String? id;
  Dloader(
    this.id,
  );

  static Dloader fromMap(Map<String, dynamic> data) {
    return Dloader(
      data['id'],
    );
  }

  static var serverUrl = 'http://localhost:8186/';

  static final Map<String, dynamic> peers = {
    // peer idm (phone number) : peer dloader client,
  };

  // static http.Client client = http.Client();

  // static Map<String, DloaderTask> clients = {};

  Map<String, dynamic> asMap() => {
        'id': id,
      };

  static final List<BotCommand> commands = [
    BotCommand(
      'cancel',
      'List server tasks queue',
      'add:https://link_here.com/example',
      (authorId, command, body) async {
        var link = body[command];
        var serverUrl = peers[authorId];
        if (serverUrl == null) {
          return 'Your server url not setted yet';
        }
        var res = await http.get(
          Uri.parse('${serverUrl}cancel'),
          headers: {'link': link},
        );
        return res.body;
      },
      UserChatState.all,
    ),
    BotCommand(
      'tasks',
      'List server tasks queue',
      'tasks',
      (authorId, command, body) async {
        var serverUrl = peers[authorId];
        if (serverUrl == null) {
          return 'Your server url not setted yet';
        }
        var res = await http.get(
          Uri.parse('${serverUrl}tasks'),
        );
        return res.body;
      },
      UserChatState.all,
    ),
    BotCommand(
      'add',
      'Add task to the tasks queue',
      'add:https://link_here.com/example',
      (authorId, command, body) async {
        var link = body[command];
        var serverUrl = peers[authorId];
        if (serverUrl == null) {
          return 'Your server url not setted yet';
        }
        var res = await http.post(
          Uri.parse('${serverUrl}add'),
          headers: {'link': link},
        );
        return res.body;
      },
      UserChatState.all,
    ),
    BotCommand(
      'status',
      'Enter ssh command',
      'status:https://link_here.com/example',
      (authorId, command, body) async {
        var link = body[command];
        var serverUrl = peers[authorId];
        if (serverUrl == null) {
          return 'Your server url not setted yet';
        }
        var res = await http.get(
          Uri.parse('${serverUrl}status'),
          headers: {'link': link},
        );
        return res.body;
      },
      UserChatState.all,
    ),
    BotCommand(
      'setdl',
      'Set your server host',
      'setdl:$serverUrl',
      (authorId, command, body) async {
        serverUrl = body[command];
        peers[authorId] = serverUrl;
        return 'OK';
      },
      UserChatState.all,
    ),
  ];
}
