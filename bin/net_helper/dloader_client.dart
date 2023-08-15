import 'package:http/http.dart' as http;
import '../../links.dart';

void main(List<String> args) async {
  // var r = await http.get(
  //   Uri.parse('http://localhost:8000/video'),
  //   headers: {
  //     'link': link,
  //     'range': '100-',
  //   },
  // );

  // print(r.statusCode);
  // print('----------------------------');
  // print(r.headers);
  // print('----------------------------');
  // print(r.bodyBytes.length);
  // print('----------------------------');

  var r = await http.post(
    // Uri.parse('http://139.59.74.96:8186/add'),
    // Uri.parse('http://167.172.167.245:8186/add'),
    Uri.parse('http://167.172.167.245:8186/refresh/number'),
    // Uri.parse('http://167.172.167.245:8186/redown'),
    // Uri.parse('http://localhost:8186/resume/0'),
    // Uri.parse('http://localhost:8186/resume'),
    // Uri.parse('http://localhost:8186/add'),
    // Uri.parse('http://localhost:8186/redown'),
    headers: {'link': link},
  );

  print(r.statusCode);
  print('----------------------------');
  print(r.headers);
  print('----------------------------');
  print(r.body);
  print('----------------------------');
}

/// 0: https://dl3.downloadly.ir/Files/Elearning/Coursera_Introduction_to_Containers_w_Docker_Kubernetes_and_OpenShift_2023_2_Downloadly.ir.rar\nDownloaded:  0 from 0\nStarted: Not Started, TryAt: 8/14 22:5 - Finised
/// 1: https://dl3.downloadly.ir/Files/Elearning/Coursera_Application_Development_using_Microservices_and_Serverless_2023_2_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:5 - Finised
/// 2: https://dl3.downloadly.ir/Files/Elearning/Coursera_Application_Security_and_Monitoring_2023_2_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:5 - Finised
/// 3: https://dl3.downloadly.ir/Files/Elearning/Coursera_Python_for_Data_Science_AI_and_Development_2023_2_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:6 - Finised
/// 4: https://dl3.downloadly.ir/Files/Elearning/Coursera_Hands_on_Introduction_to_Linux_Commands_and_Shell_Scripting_2023_2_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:6 - Finised
/// 5: https://dl3.downloadly.ir/Files/Elearning/Coursera_Introduction_to_Back-End_Development_2022-8_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:11 - Finised
/// 6: https://dl3.downloadly.ir/Files/Elearning/Coursera_Programming_in_Python_2022-8_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:11 - Finised
/// 7: https://dl3.downloadly.ir/Files/Elearning/Coursera_Introduction_to_Databases_for_Back-End_Development_2022-8_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:12 - Finised
/// 8: https://dl3.downloadly.ir/Files/Elearning/Coursera_Django_Web_Framework_2022-11_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:12 - Finised
/// 9: https://dl3.downloadly.ir/Files/Elearning/Coursera_Back_End_Developer_Capstone_2023_1_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:12 - Finised
///10: https://dl3.downloadly.ir/Files/Elearning/Coursera_Coding_Interview_Preparation_2023-2_Downloadly.ir.rar\nDownloaded: 0 from 0\nStarted: Not Started, TryAt: 8/14 22:19 - Finised"