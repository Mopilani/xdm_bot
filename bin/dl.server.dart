import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'net_helper/dloader_task.dart';

var tasksFile = File('dl.s.json');
// https://dl3.downloadly.ir/Files/Elearning/Coursera_Foundations_of_Cybersecurity_2023_5_Downloadly.ir.rar
void main(List<String> args) async {
  var sport = args.isNotEmpty ? args[0] : '8186';
  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? sport);
  final server = await serve(handler, '0.0.0.0', port);
  print('Server listening on port ${server.port}');

  var r = await tasksFile.readAsString();
  for (var entry in json.decode(r).entries) {
    clients.addAll({entry.key: DloaderTask.fromMap(entry.value)});
  }
  Future.delayed(Duration(seconds: 5), () {
    tick();
  });
}

var running = false;

Future<void> tick() async {
  running = true;
  while (running) {
    print('TICK-X');
    await Future.delayed(Duration(minutes: 10));
    print("IT'S TIME-X");
    for (var entry in [...clients.entries]) {
      print("POP-X");
      if (!entry.value.started) {
        print("PIP-X");
        await clients[entry.key]!.start();
      }
    }
  }
}

Map<String, DloaderTask> clients = {};

final router = Router()
  ..post('/add', add)
  ..post('/redown', (req) => add(req, true))
  ..get('/cancel', cancel)
  ..get('/remove', (_) {})
  ..get('/stop', (_) {})
  ..get('/resume', (_) {})
  ..get('/status', status)
  ..get('/tasks', tasks)
  ..get('/shutdown', shutdown)
  ..get('/k/<v>', (_) {});

Future<Response> cancel(Request req) async {
  var link = req.headers['link'];
  if (clients[link] != null) {
    clients[link]!.cancel();
    return Response.ok('OK');
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> shutdown(Request req) async {
  try {
    await tasksFile.writeAsString(json.encode(clients));
    var res = Response.ok('Shutting Down...');
    Future.delayed(Duration(seconds: 3), () {
      exit(0);
    });
    return res;
  } catch (e) {
    return Response.internalServerError(body: "Cant shutdown: $e");
  }
}

Future<Response> status(Request req) async {
  var link = req.headers['link'];
  if (clients[link] != null) {
    return Response.ok(clients[link]!.status());
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> tasks(Request req) async {
  var tasksList = 'Tasks: \n';
  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    tasksList += '$i: ${entry.key}\n'
        '${entry.value.downloaded} - ${entry.value.size},\n';
  }
  return Response.ok(tasksList);
}

Future<Response> add(Request req, [bool redown = false]) async {
  var link = req.headers['link'];
  if (link == null) {
    return Response.ok('You must provide a valid link');
  }
  if (clients[link] != null && !redown) {
    return Response.ok('Link was exits');
  }
  var task = DloaderTask(link);
  await task.start();
  clients.addAll({link: task});
  return Response.ok('OK');
}

Response t(Request req) {
  return Response.ok('Ok');
}

var taskss = {
  'https://dl3.downloadly.ir/Files/Elearning/Coursera_Sound_the_Alarm_Detection_and_Response_2023_5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Coursera_Sound_the_Alarm_Detection_and_Response_2023_5_Downloadly.ir.rar',
    'downloaded': 465682271,
    'size': 465682271,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Coursera_Assets_Threats_and_Vulnerabilities_2023_5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Coursera_Assets_Threats_and_Vulnerabilities_2023_5_Downloadly.ir.rar',
    'downloaded': 785724304,
    'size': 785724304,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Coursera_Tools_of_the_Trade_Linux_and_SQL_2023_5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Coursera_Tools_of_the_Trade_Linux_and_SQL_2023_5_Downloadly.ir.rar',
    'downloaded': 424047341,
    'size': 424047341,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Coursera_Connect_and_Protect_Networks_and_Network_Security_2023_5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Coursera_Connect_and_Protect_Networks_and_Network_Security_2023_5_Downloadly.ir.rar',
    'downloaded': 349607999,
    'size': 349607999,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Coursera_Automate_Cybersecurity_Tasks_with_Python_2023_5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Coursera_Automate_Cybersecurity_Tasks_with_Python_2023_5_Downloadly.ir.rar',
    'downloaded': 549716854,
    'size': 549716854,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Coursera_Put_It_to_Work_Prepare_for_Cybersecurity_Jobs_2023_5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Coursera_Put_It_to_Work_Prepare_for_Cybersecurity_Jobs_2023_5_Downloadly.ir.rar',
    'downloaded': 531244705,
    'size': 531244705,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part1_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part1_Downloadly.ir.rar',
    'downloaded': 1073741824,
    'size': 1073741824,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part2_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part2_Downloadly.ir.rar',
    'downloaded': 1073741824,
    'size': 1073741824,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part3_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part3_Downloadly.ir.rar',
    'downloaded': 1073741824,
    'size': 1073741824,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part4_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part4_Downloadly.ir.rar',
    'downloaded': 379268065,
    'size': 379268065,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': true,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Udemy_Cyber_Security_Bootcamp_2023_Become_IT_PRO_2022-11.part2_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Udemy_Cyber_Security_Bootcamp_2023_Become_IT_PRO_2022-11.part2_Downloadly.ir.rar',
    'downloaded': 1448079083,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part1_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part1_Downloadly.ir.rar',
    'downloaded': 248831723,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part2_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part2_Downloadly.ir.rar',
    'downloaded': 119537387,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part3_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part3_Downloadly.ir.rar',
    'downloaded': 120573675,
    'size': 1320887465,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part1_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part1_Downloadly.ir.rar',
    'downloaded': 171704043,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part2_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part2_Downloadly.ir.rar',
    'downloaded': 331153131,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part3_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part3_Downloadly.ir.rar',
    'downloaded': 163774187,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part4_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part4_Downloadly.ir.rar',
    'downloaded': 322516715,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part5_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part5_Downloadly.ir.rar',
    'downloaded': 294635,
    'size': 2147483648,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
  'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part6_Downloadly.ir.rar':
      DloaderTask.fromMap({
    'link':
        'https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part6_Downloadly.ir.rar',
    'downloaded': 168083180,
    'size': 697511766,
    'started': true,
    'tryAfter': DateTime.now().toString(),
    'stoptimer': true,
    'finished': false,
  }).asMap(),
};


// Tasks: 
// 0: https://dl3.downloadly.ir/Files/Elearning/Coursera_Sound_the_Alarm_Detection_and_Response_2023_5_Downloadly.ir.rar
// 465682271 - 465682271,
// 1: https://dl3.downloadly.ir/Files/Elearning/Coursera_Assets_Threats_and_Vulnerabilities_2023_5_Downloadly.ir.rar
// 785724304 - 785724304,
// 2: https://dl3.downloadly.ir/Files/Elearning/Coursera_Tools_of_the_Trade_Linux_and_SQL_2023_5_Downloadly.ir.rar
// 424047341 - 424047341,
// 3: https://dl3.downloadly.ir/Files/Elearning/Coursera_Connect_and_Protect_Networks_and_Network_Security_2023_5_Downloadly.ir.rar
// 349607999 - 349607999,
// 4: https://dl3.downloadly.ir/Files/Elearning/Coursera_Automate_Cybersecurity_Tasks_with_Python_2023_5_Downloadly.ir.rar
// 549716854 - 549716854,
// 5: https://dl3.downloadly.ir/Files/Elearning/Coursera_Put_It_to_Work_Prepare_for_Cybersecurity_Jobs_2023_5_Downloadly.ir.rar
// 531244705 - 531244705,
// 6: https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part1_Downloadly.ir.rar
// 1073741824 - 1073741824,
// 7: https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part2_Downloadly.ir.rar
// 1073741824 - 1073741824,
// 8: https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part3_Downloadly.ir.rar
// 1073741824 - 1073741824,
// 9: https://dl.downloadly.ir/Files/Elearning/Udemy_OSINT_Open_Source_Intelligence_Level_2_2022_9.part4_Downloadly.ir.rar
// 379268065 - 379268065,
// 10: https://dl3.downloadly.ir/Files/Elearning/Udemy_Cyber_Security_Bootcamp_2023_Become_IT_PRO_2022-11.part2_Downloadly.ir.rar
// 1448079083 - 2147483648,
// 11: https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part1_Downloadly.ir.rar
// 248831723 - 2147483648,
// 12: https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part2_Downloadly.ir.rar
// 119537387 - 2147483648,
// 13: https://dl3.downloadly.ir/Files/Elearning/Udemy_The_Complete_Quantum_Computing_Course_2021_7.part3_Downloadly.ir.rar
// 120573675 - 1320887465,
// 14: https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part1_Downloadly.ir.rar
// 171704043 - 2147483648,
// 15: https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part2_Downloadly.ir.rar
// 331153131 - 2147483648,
// 16: https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part3_Downloadly.ir.rar
// 163774187 - 2147483648,
// 17: https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part4_Downloadly.ir.rar
// 322516715 - 2147483648,
// 18: https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part5_Downloadly.ir.rar
// 294635 - 2147483648,
// 19: https://dl.downloadly.ir/Files/Elearning/Udemy_Complete_Ethical_Hacking_Bootcamp_2023_Zero_to_Mastery_2023_6.part6_Downloadly.ir.rar
// 168083180 - 697511766,
