import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'bot_command.dart';
import 'functions.dart';
import 'io_functions.dart';
import 'server_todo.dart';

class Author {
  String? id,
      name,
      nickname,
      username,
      description,
      twitter,
      facebook,
      youtube,
      phone,
      email;
  // bool private = false;

  Author({
    this.id,
    this.name,
    this.nickname,
    this.username,
    this.description,
    this.twitter,
    this.facebook,
    this.youtube,
    this.phone,
    this.email,
  });

  static Author fromMap(Map<String, dynamic> data) {
    return Author(
      id: data['id'],
      name: data['name'],
      nickname: data['nickname'],
      username: data['username'],
      description: data['description'],
      twitter: data['twitter'],
      facebook: data['facebook'],
      youtube: data['youtube'],
      phone: data['phone'],
      email: data['email'],
    );
  }

  Map<String, dynamic> asMap() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'username': username,
        'description': description,
        'twitter': twitter,
        'facebook': facebook,
        'youtube': youtube,
        'phone': phone,
        'email': email,
      };

  static String showAll() {
    var msg = '';
    for (var authorEntry in authors.entries) {
      msg = '$msg${authorEntry.value.show()}.\n\n';
    }
    return msg;
  }

  String show() => """الكاتب: ${name ?? 'NF'}.
  اللقب: ${nickname ?? 'NF'}.
  المعرف: ${username ?? 'NF'}@.
  الوصف: ${description ?? 'NF'}.
  Twitter: ${twitter ?? 'NF'}.
  Youtube: ${youtube ?? 'NF'}.
  Email: ${email ?? 'NF'}.""";

  static final List<BotCommand> commands = [
    BotCommand(
      'author',
      'Upgrade your self to be an Author',
      'author:<id> , lesson:1',
      (authorId, command, body) async {
        userChatStates[authorId]!['state'] = UserChatState.authorCommands;
        var author = authors[authorId];
        if (author == null) {
          author = Author(phone: authorId);
          var r = await addAuthor(author);
          if (r == 200) {
            return 'Welcome, Your are now an Author\n\n'
                'You can see your profile by sending !profile\n'
                'Commands:\n'
                '!name:Your New Name\n'
                '!nickname:Your New Nickname\n'
                '!description:New Description\n'
                '!username:New Username\n'
                '!twitter:Twitter Username\n'
                '!facebook:Facebook Username\n'
                '!youtube:New Youtube Name\n'
                '!email:new Email\n'
                '!exit:Exit edit mode\n'
                '!profile:Show your profile\n'
                'You are now in edit mode, you can edit your profile or send "!exit" to exit the mode';
          } else {
            return 'Faild to create user';
          }
        } else {
          return 'Welcome Back ${author.name}\n\n'
              'You can see your profile by sending !profile\n'
              'Commands:\n'
              '!name:Your New Name\n'
              '!nickname:Your New Nickname\n'
              '!description:New Description\n'
              '!username:New Username\n'
              '!twitter:Twitter Username\n'
              '!facebook:Facebook Username\n'
              '!youtube:New Youtube Name\n'
              '!email:new Email\n'
              '!exit:Exit edit mode\n'
              '!profile:Show your profile\n'
              'Also your are in edit mode, you can edit your profile or send "!exit" to exit the mode';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'name',
      'Change your Bot name',
      'name:<new_name> , name:Kareem Mohammed',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        author!.name = change;
        var r = await updateAuthor(author);
        if (r == 200) {
          return 'Name Changed Successfuly';
        } else {
          return 'Faild to change your name';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'nickname',
      'Change your Bot nickname',
      'nickname:<new_nickname> , name:XDM Man',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        author!.nickname = change;
        var r = await updateAuthor(author);
        if (r == 200) {
          return 'Nickname Changed Successfuly';
        } else {
          return 'Faild to change your Nickname';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'email',
      'Change your email',
      'email:<new_email> , name:xdmbot@email.com',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        author!.email = change;
        var r = await updateAuthor(author);
        if (r == 200) {
          return 'Email Changed Successfuly';
        } else {
          return 'Faild to change your Email';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'username',
      'Change your Bot username',
      'username:<new_username> , name:xdmbot',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        var newUsername = change;
        var authorInMap = authorsByUsername[newUsername];
        if (authorInMap == null) {
          author!.username = newUsername;
        } else {
          return 'This username was exists';
        }
        var r = await updateAuthor(author, author.username);
        if (r == 200) {
          return 'Username Changed Successfuly';
        } else {
          return 'Faild to change your Username';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'description',
      'Change your Bot description',
      'description:<new_description> , name:XDM Bot is some how you can say no thing.',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        author!.description = change;
        var r = await updateAuthor(author);
        if (r == 200) {
          return 'Description Changed Successfuly';
        } else {
          return 'Faild to change your Description';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'twitter',
      'Change your twitter account link',
      'twitter:<@username>',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        author!.twitter = change;
        var r = await updateAuthor(author);
        if (r == 200) {
          return 'Twitter Changed Successfuly';
        } else {
          return 'Faild to change your Twitter';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'youtube',
      'Change your youtube channel link',
      'youtube:<https://youtube.com/username>',
      (authorId, command, body) async {
        var author = authors[authorId];
        var change = body[command];
        author!.youtube = change;
        var r = await updateAuthor(author);
        if (r == 200) {
          return 'Toutube Changed Successfuly';
        } else {
          return 'Faild to change your Toutube';
        }
      },
      UserChatState.all,
    ),
    BotCommand(
      'exit',
      'Exit edit mode',
      'exit',
      (authorId, command, body) {
        userChatStates[authorId]!['state'] = UserChatState.normalMode;
        return 'Exited Edit Mode';
      },
      null,
    ),
    BotCommand(
      'profile',
      'Show Your Profile',
      'profile',
      (authorId, command, body) {
        var author = authors[authorId];
        return author!.show();
      },
      UserChatState.all,
    ),
    BotCommand(
      'debug',
      'Debug',
      'debug',
      (authorId, command, body) {
        return 'userChatStates: $userChatStates\n'
            'authors: $authors\n';
      },
      UserChatState.all,
    ),
    BotCommand(
      'mylessons',
      'Show My Lessons',
      'mylessons',
      (authorId, command, body) {
        return 'userChatStates: $userChatStates\n'
            'authors: $authors\n';
      },
      UserChatState.all,
    ),
    BotCommand(
      'myfaqs',
      'Show My Lessons',
      'mylessons',
      (authorId, command, body) {
        return 'userChatStates: $userChatStates\n'
            'authors: $authors\n';
      },
      UserChatState.all,
    ),
    BotCommand(
      'watches',
      'Show My Watches',
      'lessons',
      (authorId, command, body) {
        return 'userChatStates: $userChatStates\n'
            'authors: $authors\n';
      },
      UserChatState.authorCommands,
    ),
    BotCommand(
      'todo',
      'todo:Name Of Your Todo',
      'Create new task',
      (authorId, command, body) async {
        var name = body[command];
        var gid = body['gid'];
        var r = await ServerTODO().addToDo(name, gid);
        return r;
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'time',
      'Edit task time',
      'time:id:day:hour:minute',
      (authorId, command, body) async {
        var timeSerise = body[command] as String;
        var gid = body['gid'];
        var timeSegs = timeSerise.split(':');
        var dateTime = DateTime.now();
        var id = timeSegs[0];
        var time = DateTime(
          dateTime.year,
          int.parse(timeSegs[1]),
          int.parse(timeSegs[2]),
          int.parse(timeSegs[3]),
        );
        var r = await ServerTODO.editOnce(gid, id, time, null, null);
        return r;
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'content',
      'Edit task content',
      'content:id:The post that you want to share',
      (authorId, command, body) async {
        var change = body[command] as String;
        var gid = body['gid'];
        var timeSegs = change.split(':');
        var id = timeSegs[0];
        var content = timeSegs[1];
        var r = await ServerTODO.editOnce(gid, id, null, content, null);
        return r;
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'periodicly',
      'Periodicly execute the task',
      'periodicly:id:true|false',
      (authorId, command, body) async {
        var change = body[command] as String;
        var gid = body['gid'];
        var timeSegs = change.split(':');
        var id = timeSegs[0];
        var periodicly = (timeSegs[1] == 'true');
        var r = await ServerTODO.editOnce(gid, id, null, null, periodicly);
        return r;
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'todos',
      'Show all todos',
      'todos',
      (authorId, command, body) async {
        return ServerTODO.tasks.toString();
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'this',
      '',
      '',
      (authorId, command, body) async {
        var file = File('tpm.json');
        groupsList.addAll({
          body['gid']: false,
        });
        await file.writeAsString(json.encode(groupsList));
        return 'OK';
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'loadgroups',
      '',
      '',
      (authorId, command, body) async {
        var file = File('tpm.json');
        var r = await file.readAsString();
        groupsList = json.decode(r);
        return 'OK';
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'tick',
      '',
      '',
      (authorId, command, body) async {
        tick();
        return 'OK';
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'send',
      '',
      '',
      (authorId, command, body) async {
        await http.post(
          Uri.parse('http://localhost:$xport/post'),
          headers: {
            'receiver': groupsList.entries.first.key,
            HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
          },
          body: json.encode({'content': content}),
        );
        return 'OK';
      },
      UserChatState.all,
      adminCommand: true,
    ),
  ];

  static final xport = 8156;

  static var running = false;

  static Future<void> tick() async {
    running = true;
    while (running) {
      await Future.delayed(Duration(seconds: 30));
      print('TICK');
      var nd = DateTime.now();
      if ((DateTime(
                nd.year,
                nd.month,
                nd.day,
                6,
                27,
                0,
              ).millisecondsSinceEpoch <
              nd.millisecondsSinceEpoch) &&
          DateTime(
                nd.year,
                nd.month,
                nd.day,
                6,
                27,
                30,
              ).millisecondsSinceEpoch >
              nd.millisecondsSinceEpoch) {
        print("IT'S TIME");
        for (var entry in [...groupsList.entries]) {
          print("POP");
          if (!groupsList[entry.key]) {
            print("PIP");
            await http.post(
              Uri.parse('http://localhost:$xport/post'),
              headers: {
                'receiver': entry.key,
                HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
              },
              body: json.encode({'content': content}),
            );
            print("FIOOO");
            groupsList[entry.key] = true;
          }
        }
      }
    }
  }
}

Map<String, dynamic> groupsList = {
  // 'gid': ,
  // 'done': ,
};

var content = """https://chat.whatsapp.com/FrWExYrIHIX14ANgzfK14W
دة قروب يجمع الكل سناير والناس الجديدة للاستفسارات والأسئلة
الناس اللي حتنزل يوم 17 يوليو
خشو القروب دة
https://chat.whatsapp.com/D2BHQm52QYwL4slVrTeX5J
الناس الجديدة وحتنزل شهر 8
خشو القروب دة
https://chat.whatsapp.com/K1ZIISnsJPIKhMyBbDGfLk
الناس اللي عابرة وعاوزة تتناقش نقاشات كبيرة كبيرة تخش القروب دة😂
https://chat.whatsapp.com/K8rROUa4FJCKsaQQ7ewcBt """;
// var taskList = [
// {
//   time: ,
// }
// ];


