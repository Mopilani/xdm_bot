import 'author.dart';
import 'bot_command.dart';
import 'functions.dart';
import 'io_functions.dart';

class Lesson {
  String id, title, content;
  Author author;
  DateTime? createTime, updateTime;

  Lesson(
    this.id,
    this.title,
    this.content, {
    required this.author,
    this.createTime,
    this.updateTime,
  });

  String getKeyByAPAndId() =>
      '${author.phone!.toLowerCase()}:${id.toLowerCase()}';
  String getKeyByAUAndId() =>
      '${author.username!.toLowerCase()}:${id.toLowerCase()}';
  // String getKeyByTheBest() => '${author.username!.toLowerCase()}:${id.toLowerCase()}';

  static String getKeyByIdFrom(String username, String lessonId) =>
      '${username.toLowerCase()}:${lessonId.toLowerCase()}';

  String getKeyByTitle() => title;

  static String showAll(LessonsCount count, [authorId]) {
    var msg =
        ((count == LessonsCount.all) ? 'All Lessons:\n' : 'This month:\n');
    msg = ((count == LessonsCount.author) ? 'Author Lessons:\n' : msg);

    if (lessonsByTitle.isEmpty) {
      msg = '''$msg

لا يوجد شروحات حتى الان.''';
    }
    if (authorId != null) {
      for (var lessonEntry in lessonsById.entries) {
        if (lessonEntry.key.contains(authorId)) {
          msg = '''
$msg
*${lessonEntry.value.title}*
  L:${lessonEntry.value.getKeyByAUAndId()}''';
        }
      }
    } else {
      for (var lessonEntry in lessonsById.entries) {
        msg = '''
$msg
*${lessonEntry.value.title}*
  L:${lessonEntry.value.getKeyByAUAndId()}''';
      }
    }
    return '$msg\n\n'
        ':اكتب اسم الدرس هكذا\n'
        'L:author:id\n'
        'يجب ان يبدأ الدرس بـ "L:"';
  }

  String show() => """الكاتب: ${author.name} - ${author.nickname}.
Title: *$title*
L:${getKeyByAUAndId()}
 $content

Date & Time: ${formate(updateTime)}.""";

  static final List<BotCommand> commands = [
    BotCommand(
      'lesson',
      'Create New Lesson Or Open Edit Mode',
      'lesson:<id> , lesson:1',
      (authorId, command, body) async {
        // var commandSegs = command.split(':');
        // var lessonId = commandSegs.last;
        print(body);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add lessons';
        }
        var lessonId = body[command];
        if (lessonId == '') {
          return 'You must provide a valid id.';
        }
        userChatStates[authorId]!['state'] = UserChatState.lessonCommands;
        var lesson =
            lessonsById[Lesson.getKeyByIdFrom(authorInMap.username!, lessonId)];
        userChatStates[authorId]!['lsId'] = lessonId;
        if (lesson == null) {
          lesson = Lesson(
            lessonId,
            'Title',
            'Content\n',
            author: authors[authorId]!,
          );
          lesson.createTime = DateTime.now();
          lesson.updateTime = DateTime.now();
          var r = await addLesson(lesson);
          if (r == 500) {
            userChatStates[authorId]!['state'] = UserChatState.normalMode;
            return 'Faild to create lesson';
          } else if (r == 201) {
            userChatStates[authorId]!['state'] = UserChatState.normalMode;
            return 'Lesson Already Exists';
          } else {
            return r;
          }
        } else {
          return 'On edit mode for lesson $lessonId\n${lesson.show()}';
        }
        // return 'Switch to edit mode, Lesson $lessonId - ${lesson.title}';
      },
      UserChatState.normalMode,
    ),
    BotCommand(
      'title',
      'Change Lesson Title',
      'title:<new_title> , title:Shell',
      (authorId, command, body) async {
        var lessonId = userChatStates[authorId]!['lsId'];
        // var change = (command.split(':').last);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add lessons';
        }
        var change = body[command];
        var lesson =
            lessonsById[Lesson.getKeyByIdFrom(authorInMap.username!, lessonId)];
        lesson!.title = change;
        var r = await updateLesson(lesson, true);
        if (r == 500) {
          return 'Faild to create lesson';
        } else if (r == 201) {
          return 'Lesson Already Exists';
        } else {
          return 'Lesson Title Changed Successfuly';
        }
      },
      UserChatState.lessonCommands,
    ),
    BotCommand(
      'content',
      'Change Lesson Content',
      'content:<Content> , content:Hello World',
      (authorId, command, body) async {
        var lessonId = userChatStates[authorId]!['lsId'];
        // var change = (command.split(':').last);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add lessons';
        }
        var change = body[command];
        var lesson =
            lessonsById[Lesson.getKeyByIdFrom(authorInMap.username!, lessonId)];
        lesson!.content = change;
        lesson.updateTime = DateTime.now();
        var r = await updateLesson(lesson, true);
        if (r == 500) {
          return 'Faild to create lesson';
        } else if (r == 201) {
          return 'Lesson Already Exists';
        } else {
          return 'Lesson Content Changed Successfuly';
        }
      },
      UserChatState.lessonCommands,
    ),
    BotCommand(
      'show',
      'Show the lesson',
      'show',
      (authorId, command, body) async {
        var lessonId = userChatStates[authorId]!['lsId'];
        // var change = (command.split(':').last);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add lessons';
        }
        var lesson =
            lessonsById[Lesson.getKeyByIdFrom(authorInMap.username!, lessonId)];
        return lesson!.show();
      },
      UserChatState.lessonCommands,
    ),
    BotCommand(
      'delete',
      'Delete Lesson',
      'delete:<id> , delete:1',
      (authorId, command, body) async {
        await deleteLesson(authorId);
        return 'Lesson Deleted Successfuly';
      },
      UserChatState.lessonCommands,
    ),
    BotCommand(
      'exit',
      'Exit edit lesson mode',
      'exit',
      (authorId, command, body) {
        userChatStates[authorId]!['state'] = UserChatState.normalMode;
        return 'Exited From Edit Lesson Mode';
      },
      null,
    ),
  ];

  static Lesson fromMap(Map<String, dynamic> data) {
    return Lesson(
      data['id'],
      data['title'],
      data['content'],
      author: authors[data['author']] ?? Author(),
      createTime: DateTime.tryParse(data['createTime'] ?? ''),
      updateTime: DateTime.tryParse(data['updateTime'] ?? ''),
    );
  }

  Map<String, dynamic> asMap() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author.phone,
        'createTime': createTime.toString(),
        'updateTime': updateTime.toString(),
      };
}
// String excuteCommand(String userid, String command) {
//   BotCommand? botCommand;
//   try {
//     botCommand = commandsMap[(command.split(':').first)];
//   } catch (e) {
//     return 'Command Not Found';
//   }
//   if (botCommand == null) {
//     return botCommand!.function(userid, command);
//     // if (command.startsWith('${commands[0]}:')) {
//     //   id = command.substring('${commands[0]}:'.length);
//     //   return show();
//     // } else if (command.startsWith('${commands[1]}:')) {
//     //   title = command.substring('${commands[1]}:'.length);
//     //   return show();
//     // } else if (command.startsWith('${commands[2]}:')) {
//     //   content = command.substring('${commands[2]}:'.length);
//     //   return show();
//   } else {
//     return 'Command Not Found';
//   }
// }

// String excuteCommand(String command) {
//   if (command.startsWith('${commands[0]}:')) {
//     name = command.substring('${commands[0]}:'.length);
//     return show();
//   } else if (command.startsWith('${commands[1]}:')) {
//     nickname = command.substring('${commands[1]}:'.length);
//     return show();
//   } else if (command.startsWith('${commands[2]}:')) {
//     twitter = command.substring('${commands[2]}:'.length);
//     return show();
//   } else if (command.startsWith('${commands[3]}:')) {
//     description = command.substring('${commands[3]}:'.length);
//     return show();
//   } else if (command.startsWith('${commands[4]}:')) {
//     youtube = command.substring('${commands[4]}:'.length);
//     return show();
//   } else if (command.startsWith('${commands[5]}:')) {
//     email = command.substring('${commands[5]}:'.length);
//     return show();
//   } else if (command.startsWith('${commands[6]}:')) {
//     username = command.substring('${commands[6]}:'.length);
//     return show();
//   } else {
//     return 'Command Not Found';
//   }
// }
