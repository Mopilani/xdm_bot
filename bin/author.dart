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
      'mylessons',
      (authorId, command, body) {
        var name = body[command];
        var gid = body['gid'];
        // var time = ;
        ServerTODO().addToDo(name, gid);
        return 'TODO Saved Admin!';
      },
      UserChatState.all,
      adminCommand: true,
    ),
    BotCommand(
      'time',
      'Edit task time',
      'time:id:day:hour:minute',
      (authorId, command, body) {
        var timeSerise = body[command] as String;
        var timeSegs = timeSerise.split(':');
        var gid = body[command];
        var dateTime = DateTime.now();
        var id = timeSegs[0];
        var time = DateTime(
          dateTime.year,
          int.parse(timeSegs[1]),
          int.parse(timeSegs[2]),
          int.parse(timeSegs[3]),
        );
        ServerTODO().editOnce(gid, id, time.toString(), null);
        return 'TODO Saved Admin!';
      },
      UserChatState.all,
      adminCommand: true,
    ),
  ];
}
