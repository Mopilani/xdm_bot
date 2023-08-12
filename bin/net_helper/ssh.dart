import '../bot_command.dart';
import '../functions.dart';
import 'ssh_connector.dart';

class SSHClient {
  String? id;
  SSHClient(
    this.id,
  );

  static SSHClient fromMap(Map<String, dynamic> data) {
    return SSHClient(
      data['id'],
    );
  }

  static Map<String, SSHClientBridge> clients = {};

  Map<String, dynamic> asMap() => {
        'id': id,
      };

  static final List<BotCommand> commands = [
    BotCommand(
      'exit',
      'Set your ssh client',
      'ssh:a6a2a3b4b2b5.c02c427b.alx-cod.online',
      (authorId, command, body) async {
        userChatStates[authorId]!['state'] = UserChatState.normalMode;
        return 'Exited mode';
      },
      UserChatState.sshCommands,
      adminCommand: true,
    ),
    BotCommand(
      'stop',
      'Set your ssh client',
      'ssh:a6a2a3b4b2b5.c02c427b.alx-cod.online',
      (authorId, command, body) async {
        try {
          clients[authorId]!.stop();
        } catch (e) {
          //
        }
        return 'Exited (0)';
      },
      UserChatState.sshCommands,
      adminCommand: true,
    ),
    BotCommand(
      'start',
      'Set your ssh client',
      'ssh:a6a2a3b4b2b5.c02c427b.alx-cod.online',
      (authorId, command, body) async {
        try {
          clients[authorId]!.start();
          return 'Started';
        } catch (e) {
          return 'Err: $e';
        }
      },
      UserChatState.sshCommands,
      adminCommand: true,
    ),
    BotCommand(
      'ssh',
      'Enter ssh mode',
      'ssh:o',
      (authorId, command, body) async {
        userChatStates[authorId]!['state'] = UserChatState.sshCommands;
        return 'OK';
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      's',
      'Enter ssh command',
      's:Your command',
      (authorId, command, body) async {
        userChatStates[authorId]!['state'] = UserChatState.sshCommands;
        return 'OK';
      },
      UserChatState.sshCommands,
      adminCommand: true,
    ),
    BotCommand(
      'set',
      'Set your ssh client host',
      'set:a6a2a3b4b2b5.c023c54eb.alx-cod.online',
      (authorId, command, body) async {
        var sshHots = body[command];
        var client = SSHClientBridge(sshHots);
        try {
          await client.start();
          client.bind(client.whatsClientCallBack(authorId));
          clients.addAll({authorId: client});
          return 'OK';
        } catch (e) {
          return 'Err: $e';
        }
      },
      UserChatState.sshCommands,
      adminCommand: true,
    ),
  ];
}
