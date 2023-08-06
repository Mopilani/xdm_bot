import 'dart:convert';
import 'dart:io';

import 'author.dart';
import 'functions.dart';
import 'lesson.dart';
import 'faq.dart';

// var lessonsList = """مرحا بك في القروب
// انا روبوت يمكنني تقديم المساعد والشروحات اليك

// قائمة الشروحات:
// 1. Shell
// 2. Emacs
// 3. Vi

// اكتب اسم الدرس من فضلك
// """;

// var shell = """Shell - الصدفة
// المفهوم العام: يمكننا دعوتها بالصدفة لفهم انها تعتبر صدفة نواة النظام لكن وتمكننا من التواصل مع النظام بطريقة مباشرة والاستفادة من خصائصه.

// في درس ال shell
// """;

var greatingMsg = """مرحا بك في القروب
انا روبوت يمكنني تقديم المساعد والشروحات اليك.
* لاستعراض قائمة الشروحات ارسل lessons أو اكتب اسم الدرس من فضلك.
""";

Map<String, Lesson> lessonsByTitle = {
  // lesson.title : Lesson()
};

Map<String, Lesson> lessonsById = {
  // author.username ?? author.phone:lesson.id : Lesson()
};

Map<String, FAQ> freqAskedQues = {
  // author.username ?? author.phone:lesson.id : Lesson()
};

Map<String, Author> authors = {
  // 'phone' : Author()
};
Map<String, Author> authorsByUsername = {
  // 'username' : Author()
};

const String lessonsFile = 'lessons.json';
const String freqAskedQuesFile = 'faq.json';
const String authorsFile = 'authors.json';

// DONE
Future<int> loadLessons() async {
  var db = File(lessonsFile);
  var data = await db.readAsString();
  if (data.isNotEmpty) {
    var lessonsMap = json.decode(data);
    for (var lessonData in lessonsMap.values) {
      Lesson lesson = Lesson.fromMap(lessonData);
      lessonsById.addAll({lesson.getKeyByAUAndId(): lesson});
      lessonsByTitle.addAll({lesson.getKeyByTitle(): lesson});
    }
  }
  return 200;
}

Future<int> loadfreqAskedQues() async {
  var db = File(freqAskedQuesFile);
  var data = await db.readAsString();
  if (data.isNotEmpty) {
    var lessonsMap = json.decode(data);
    for (var lessonData in lessonsMap.values) {
      FAQ faq = FAQ.fromMap(lessonData);
      freqAskedQues.addAll({faq.getKeyByAUAndId(): faq});
      // lessonsByTitle.addAll({lesson.getKeyByTitle(): lesson});
    }
  }
  return 200;
}

// _loadAuthors() {}

// DONE
Future<int> loadAuthors() async {
  var db = File(authorsFile);
  var data = await db.readAsString();
  if (data.isNotEmpty) {
    var authorsMap = json.decode(data);
    for (var authorData in authorsMap.values) {
      Author author = Author.fromMap(authorData);
      authors.addAll({author.phone!: author});
      if (author.username != null) {
        authorsByUsername.addAll({author.username!: author});
      }
    }
  }
  return 200;
}

// DONE
Future<dynamic> addLesson(Lesson lesson, [bool update = false]) async {
  try {
    if (!update && lessonsById[lesson.getKeyByAUAndId()] != null) {
      return 201;
    }
    var db = File(lessonsFile);
    lessonsById.addAll({lesson.getKeyByAUAndId(): lesson});
    lessonsByTitle.addAll({lesson.getKeyByTitle(): lesson});
    var dryLessons = <String, dynamic>{};
    for (var lesson in lessonsById.values) {
      dryLessons.addAll({lesson.getKeyByAUAndId(): lesson.asMap()});
    }
    await db.writeAsString(json.encode(dryLessons));
    return lesson.show();
  } catch (e, s) {
    print(e);
    print(s);
    return 500;
  }
}

Future<dynamic> addFaq(FAQ faq, [bool update = false]) async {
  try {
    if (!update && freqAskedQues[faq.getKeyByAUAndId()] != null) {
      return 201;
    }
    var db = File(freqAskedQuesFile);
    freqAskedQues.addAll({faq.getKeyByAUAndId(): faq});
    var dryFaqs = <String, dynamic>{};
    for (var faq in freqAskedQues.values) {
      dryFaqs.addAll({faq.getKeyByAUAndId(): faq.asMap()});
    }
    await db.writeAsString(json.encode(dryFaqs));
    return faq.show();
  } catch (e, s) {
    print(e);
    print(s);
    return 500;
  }
}

// DONE
Future<int> deleteLesson(String authorId) async {
  try {
    var lessonKey = userChatStates[authorId]!['lsId'];
    var db = File(lessonsFile);
    lessonsById.remove(lessonKey);
    lessonsByTitle.remove(lessonKey);
    var dryLessons = <String, dynamic>{};
    for (var lesson in lessonsById.values) {
      dryLessons.addAll({lesson.getKeyByAUAndId(): lesson.asMap()});
    }
    await db.writeAsString(json.encode(dryLessons));
    return 200;
  } catch (e) {
    return 500;
  }
}

Future<int> deleteFAQ(String authorId) async {
  try {
    var faqKey = userChatStates[authorId]!['faqId'];
    var db = File(freqAskedQuesFile);
    freqAskedQues.remove(faqKey);
    var dryFreqAskedQues = <String, dynamic>{};
    for (var faq in freqAskedQues.values) {
      dryFreqAskedQues.addAll({faq.getKeyByAUAndId(): faq.asMap()});
    }
    await db.writeAsString(json.encode(dryFreqAskedQues));
    return 200;
  } catch (e) {
    return 500;
  }
}

Future<dynamic> updateLesson(Lesson lesson, [bool update = false]) async {
  return await addLesson(lesson, update);
}

Future<dynamic> updateFaq(FAQ faq, [bool update = false]) async {
  return await addFaq(faq, update);
}

Future<int> addAuthor(Author author, [String? oldUsername]) async {
  try {
    var db = File(authorsFile);
    authors.addAll({author.phone!: author});
    if (author.username != null) {
      if (oldUsername != null) {
        authorsByUsername.remove(oldUsername);
      }
      authorsByUsername.addAll({author.username!: author});
    }
    var dryAuthors = <String, dynamic>{};
    for (var author in authors.values) {
      dryAuthors.addAll({author.phone!: author.asMap()});
    }
    await db.writeAsString(json.encode(dryAuthors));
    return 200;
  } catch (e, s) {
    print(e);
    print(s);
    return 500;
  }
}

Future<int> deleteAuthor(String authorPhone) async {
  try {
    var db = File(authorsFile);
    var author = authors[authorPhone];
    authors.remove(authorPhone);
    if (author!.username != null) {
      authorsByUsername.remove(author.username);
    }
    var dryAuthors = <String, dynamic>{};
    for (var author in authors.values) {
      dryAuthors.addAll({author.phone!: author.asMap()});
    }
    await db.writeAsString(json.encode(dryAuthors));
    return 200;
  } catch (e) {
    return 500;
  }
}

Future<int> updateAuthor(Author author, [String? oldUsername]) async {
  return await addAuthor(author, oldUsername);
}
