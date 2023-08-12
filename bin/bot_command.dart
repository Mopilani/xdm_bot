import 'dart:async';
import 'dart:convert';

import 'author.dart';
import 'faq.dart';
import 'functions.dart';
import 'io_functions.dart';
import 'lesson.dart';
import 'net_helper/ssh.dart';

class BotCommand {
  final String command, descripton, usage;
  final FutureOr<String> Function(String arg, String arg2, dynamic body)
      function;
  final UserChatState? neededState;
  final bool? adminCommand;

  static final List<String> adminsList = <String>[
    '249901503116@c.us',
    '249912773910@c.us',
    '249128430708@c.us',
  ];

  BotCommand(
    this.command,
    this.descripton,
    this.usage,
    this.function,
    this.neededState, {
    this.adminCommand = false,
  });

  String show() => '''!$command
  $descripton
  $usage
  ${neededState?.name}''';

  static String showAll() {
    var commands = <BotCommand>[];
    commands.addAll(Lesson.commands);
    commands.addAll(Author.commands);
    var commandsMsg = '';
    for (var command in commands) {
      commandsMsg = '$commandsMsg${command.show()}\n';
    }
    return commandsMsg;
  }

  static final Map<String, BotCommand> commandsMap = {
    'faqs': BotCommand(
      'faqs',
      'Show all the faqs',
      'faqs',
      (authroId, command, body) async {
        return '';
      },
      UserChatState.all,
    ),
    'gfaq': BotCommand(
      'gfaq',
      'Show all the faqs',
      'gfaq:Git',
      (authroId, command, body) async {
        var about = body[command];
        // var faq = freqAskedQues[about.toLowerCase()];
        Map<String, FAQ> result = {};
        for (var entry in freqAskedQues.entries) {
          print(entry.value.ask.toLowerCase());
          if (entry.value.ask.toLowerCase().contains(about)) {
            result.addEntries([entry]);
          }
        }

        if (result.isNotEmpty) {
          StringBuffer buffer = StringBuffer();
          result.forEach((key, value) {
            buffer.write(value.show());
          });

          return buffer.toString();
        } else {
          return 'نتأسف لا يوجد لدينا ما يطابق سؤالك, يمكنك تجربة البحث على Google او المحاولة مرة اخرى';
        }
      },
      UserChatState.all,
    ),
  };

  static void loadCommands() {
    for (var command in Author.commands) {
      commandsMap.addAll({command.command: command});
    }
    for (var command in Lesson.commands) {
      commandsMap.addAll({command.command: command});
    }
    for (var command in FAQ.commands) {
      commandsMap.addAll({command.command: command});
    }
    for (var command in SSHClient.commands) {
      commandsMap.addAll({command.command: command});
    }
  }

  static Future<String> excuteCommand(
    String authroId,
    String command,
    dynamic body,
  ) async {
    print('Body: $body');
    try {
      body = json.decode(body);
    } catch (e) {
      //
    }
    BotCommand? botCommand;
    try {
      // if (command.contains(':')) {
      //   botCommand = BotCommand.commandsMap[command.split(':').first];
      //   botCommand ??= BotCommand.commandsMap[command];
      // } else {
      botCommand = BotCommand.commandsMap[command];
      // }
      // return '';
    } catch (e) {
      return 'Command $command Not Found $e';
    }

    if (botCommand == null) {
      return 'Command $command Not Found';
    } else {
      if (botCommand.adminCommand == true) {
        if (adminsList.contains(authroId)) {
          // continue;
        } else {
          return 'This command just allowed for admins';
        }
      }
      if (userChatStates[authroId] == null) {
        userChatStates[authroId] = {
          'state': UserChatState.normalMode,
          'lsId': null,
        };
      }
      if (userChatStates[authroId]!['state'] == botCommand.neededState ||
          botCommand.neededState == UserChatState.all ||
          botCommand.neededState == null) {
        return await botCommand.function(authroId, command, body);
      } else {
        return 'userChatStates: $userChatStates\n'
            '\n'
            'Your Current State is ${userChatStates[authroId]!['state']}, You need to enter the ${botCommand.neededState?.name}';
      }
    }
  }
}
