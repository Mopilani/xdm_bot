
// Configure routes.
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'author.dart';
import 'bot_command.dart';
import 'faq_class.dart';
import 'functions.dart';
import 'io_functions.dart';
import 'lesson_class.dart';

final router = Router()
  ..get('/greating', greating)
  ..get('/authors', getAuthors)
  ..get('/author/<phone>', _author)
  ..get('/commands', commands)
  ..post('/command/<phone>/<command>', _command)
  ..post('/acommand/<phone>/<command>', _command)
  ..get('/all-lessons', allLessons)
  ..get('/month-lessons', monthLessons)
  ..get('/faq/<about>', faqEndpoint)
  ..get('/lesson/<lessonName>', getLesson);

// DONE
Response greating(Request req) {
  return Response.ok(greatingMsg);
}

// DONE
Response _author(Request req) {
  final phone = req.params['phone'];
  var author = authors[phone];
  if (author != null) {
    return Response.ok(author.show());
  }
  return Response.notFound('نتأسف لا يوجد لدينا ما يطابق سؤالك, يمكنك تجربة البحث على Google او المحاولة مرة اخرى');
}

// DONE
Future<Response> _command(Request req) async {
  final command = req.params['command'];
  final phone = req.params['phone'];
  var body = utf8.decode(await req.read().first);
  try {
    var r = await BotCommand.excuteCommand(phone!, command!, body);
    return Response.ok(r);
  } catch (e, s) {
    print(e);
    print(s);
    return Response.internalServerError(body: 'FATAL ERROR: $e');
  }
}

// DONE
Response getLesson(Request req) {
  final _lesson = req.params['lessonName'];
  var lesson = lessonsById[_lesson?.toLowerCase()];
  print('Getting lesson... $_lesson - $lesson');
  if (lesson != null) {
    return Response.ok(lesson.show());
  } else {
    lesson = lessonsByTitle[_lesson?.toLowerCase()];
    if (lesson != null) {
      return Response.ok(lesson.show());
    }
  }
  return Response.notFound('نتأسف لا يوجد لدينا ما يطابق سؤالك, يمكنك تجربة البحث على Google او المحاولة مرة اخرى');
}

Response faqEndpoint(Request req) {
  final about = req.params['about'];
  if (about == null) {
    return Response.ok('لازم تحدد لي انت عاوز اجابات عن شنو بالظبط.');
  }

  var faq = freqAskedQues[about.toLowerCase()];
  Map<String, FAQ> result = {};
  for (var entry in freqAskedQues.entries) {
    if (entry.key.contains(about)) {
      result.addEntries([entry]);
    }
  }

  if (faq != null) {
    StringBuffer buffer = StringBuffer();
    result.forEach((key, value) {
      buffer.write(value.show());
    });

    return Response.ok(buffer);
  } else {
    return Response.notFound('متأسف ما لقيت حاجة والله');
  }
}

// DONE
Response getAuthors(Request req) {
  return Response.ok(Author.showAll());
}

// DONE
Response allLessons(Request req) {
  return Response.ok(Lesson.showAll(LessonsCount.all));
}

// DONE
Response monthLessons(Request req) {
  return Response.ok(Lesson.showAll(LessonsCount.thisMonth));
}

// DONE
Response commands(Request req) {
  return Response.ok(BotCommand.showAll());
}