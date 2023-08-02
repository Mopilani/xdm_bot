import 'author.dart';
import 'bot_command.dart';
import 'functions.dart';
import 'io_functions.dart';

class FAQ {
  String id, ask, ans;
  Author author;
  DateTime? createTime, updateTime;

  FAQ(
    this.id,
    this.ask,
    this.ans, {
    required this.author,
    this.createTime,
    this.updateTime,
  });

  // String getKeyByAPAndId() =>
  //     '${author.phone!.toLowerCase()}:${id.toLowerCase()}';
  String getKeyByAUAndId() =>
      '${author.username!.toLowerCase()}:${id.toLowerCase()}';
  // String getKeyByTheBest() => '${author.username!.toLowerCase()}:${id.toLowerCase()}';

  static String getKeyByIdFrom(String username, String faqId) =>
      '${username.toLowerCase()}:${faqId.toLowerCase()}';

  // String getKeyByTitle() => title;

  static String showAll(LessonsCount count) {
    var msg = count == LessonsCount.all ? 'All FAQs:\n' : 'This month:\n';
    if (freqAskedQues.isEmpty) {
      msg = '''$msg

لا يوجد شروحات حتى الان.''';
    }
    for (var faqEntry in freqAskedQues.entries) {
      msg = '''
$msg
*${faqEntry.value.ask}*
  l:${faqEntry.value.getKeyByAUAndId()}.''';
    }
    return '$msg\n\n'
        ':اكتب اسم الدرس هكذا\n'
        'l:id:author\n'
        'يجب ان يبدأ الدرس بـ "l:"';
  }

  String show() => """${author.name} - ${author.nickname}.
Title: *$ask*
faq:$id
 $ans

Date & Time: ${formate(updateTime)}.""";

  static final List<BotCommand> commands = [
    BotCommand(
      'faq',
      'Create New FAQ Or Open Edit Mode',
      'faq:<id> , faq:1',
      (authorId, command, body) async {
        print(body);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add faqs';
        }
        var faqId = body[command];
        if (faqId == '') {
          return 'You must provide a valid id.';
        }
        userChatStates[authorId]!['state'] = UserChatState.faqCommands;
        var faq =
            freqAskedQues[FAQ.getKeyByIdFrom(authorInMap.username!, faqId)];
        userChatStates[authorId]!['faqId'] = faqId;
        if (faq == null) {
          faq = FAQ(
            faqId,
            'Ask',
            'Answer\n',
            author: authors[authorId]!,
          );
          faq.createTime = DateTime.now();
          faq.updateTime = DateTime.now();
          var r = await addFaq(faq);
          if (r == 500) {
            userChatStates[authorId]!['state'] = UserChatState.normalMode;
            return 'Faild to create FAQ';
          } else if (r == 201) {
            userChatStates[authorId]!['state'] = UserChatState.normalMode;
            return 'FAQ Already Exists';
          } else {
            return r;
          }
        } else {
          return 'On edit mode for faq $faqId\n${faq.show()}';
        }
      },
      UserChatState.normalMode,
    ),
    BotCommand(
      'ask',
      'Change FAQ Ask',
      'ask:<new_ask> , ask:Git',
      (authorId, command, body) async {
        var faqId = userChatStates[authorId]!['faqId'];
        // var change = (command.split(':').last);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add faqs';
        }
        var change = body[command];
        var faq =
            freqAskedQues[FAQ.getKeyByIdFrom(authorInMap.username!, faqId)];
        faq!.ask = change;
        var r = await updateFaq(faq, true);
        if (r == 500) {
          return 'Faild to create FAQ';
        } else if (r == 201) {
          return 'FAQ Already Exists';
        } else {
          return 'FAQ Title Changed Successfuly';
        }
      },
      UserChatState.faqCommands,
    ),
    BotCommand(
      'ans',
      'Change FAQ Content',
      'ans:<Content> , ans:Answer for ques about Git',
      (authorId, command, body) async {
        var faqId = userChatStates[authorId]!['faqId'];
        // var change = (command.split(':').last);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add faqs';
        }
        var change = body[command];
        var faq =
            freqAskedQues[FAQ.getKeyByIdFrom(authorInMap.username!, faqId)];
        faq!.ans = change;
        faq.updateTime = DateTime.now();
        var r = await updateFaq(faq, true);
        if (r == 500) {
          return 'Faild to create faq';
        } else if (r == 201) {
          return 'FAQ Already Exists';
        } else {
          return 'FAQ Content Changed Successfuly';
        }
      },
      UserChatState.faqCommands,
    ),
    BotCommand(
      'show',
      'Show the faq',
      'show',
      (authorId, command, body) async {
        var faqId = userChatStates[authorId]!['faqId'];
        // var change = (command.split(':').last);
        var authorInMap = authors[authorId];
        if (authorInMap == null) {
          return 'You must have username to add faqs';
        }
        var faq =
            freqAskedQues[FAQ.getKeyByIdFrom(authorInMap.username!, faqId)];
        return faq!.show();
      },
      UserChatState.faqCommands,
    ),
    BotCommand(
      'delete',
      'Delete FAQ',
      'delete:<id> , delete:1',
      (authorId, command, body) async {
        await deleteLesson(authorId);
        return 'FAQ Deleted Successfuly';
      },
      UserChatState.faqCommands,
    ),
    BotCommand(
      'exit',
      'Exit edit FAQ mode',
      'exit',
      (authorId, command, body) {
        userChatStates[authorId]!['state'] = UserChatState.normalMode;
        return 'Exited From Edit FAQ Mode';
      },
      null,
    ),
    BotCommand(
      'asks',
      'عرض كل الاسأئلة',
      'asks',
      (authorId, command, body) {
        StringBuffer buffer = StringBuffer();
        for (var askEntry in freqAskedQues.entries) {
          buffer.write('''*${askEntry.value.ask}*
  ${askEntry.key}\n''');
        }
        return buffer.toString();
      },
      null,
    ),
  ];

  static FAQ fromMap(Map<String, dynamic> data) {
    return FAQ(
      data['id'],
      data['ask'],
      data['ans'],
      author: authors[data['author']] ?? Author(),
      createTime: DateTime.tryParse(data['createTime'] ?? ''),
      updateTime: DateTime.tryParse(data['updateTime'] ?? ''),
    );
  }

  Map<String, dynamic> asMap() => {
        'id': id,
        'ask': ask,
        'ans': ans,
        'author': author.phone,
        'createTime': createTime.toString(),
        'updateTime': updateTime.toString(),
      };
}
