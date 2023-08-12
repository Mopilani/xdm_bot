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
      'stop',
      'Set your ssh client',
      'ssh:a6a2a3b4b2b5.c02c427b.alx-cod.online',
      (authorId, command, body) async {
        return 'OK';
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'ssh',
      'Set your ssh client',
      'ssh:a6a2a3b4b2b5.c023c54eb.alx-cod.online',
      (authorId, command, body) async {
        var sshHots = body[command];
        var client = SSHClientBridge(sshHots);
        client.bind(client.whatsClientCallBack(authorId));
        clients.addAll({authorId: client});
        try {
          await client.start();
          return 'OK';
        } catch (e) {
          return 'Err: $e';
        }
      },
      UserChatState.all,
      adminCommand: true,
    ),
  ];
}
