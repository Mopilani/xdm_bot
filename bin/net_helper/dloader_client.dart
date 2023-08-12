import 'package:http/http.dart' as http;

void main(List<String> args) async {
  var r = await http.post(
    Uri.parse('http://167.172.167.245:8186/add'),
    headers: {
      'link':
          ''
          // ''
          // ''
          // ''
          // 'https://dl3.downloadly.ir/Files/Elearning/Coursera_Assets_Threats_and_Vulnerabilities_2023_5_Downloadly.ir.rar'
          // 'https://dl3.downloadly.ir/Files/Elearning/Coursera_Tools_of_the_Trade_Linux_and_SQL_2023_5_Downloadly.ir.rar'
          // 'https://dl3.downloadly.ir/Files/Elearning/Coursera_Connect_and_Protect_Networks_and_Network_Security_2023_5_Downloadly.ir.rar'
          // 'https://dl3.downloadly.ir/Files/Elearning/Coursera_Play_It_Safe_Manage_Security_Risks_2023_5_Downloadly.ir.rar'
          // 'https://dl3.downloadly.ir/Files/Elearning/Coursera_Foundations_of_Cybersecurity_2023_5_Downloadly.ir.rar'
    },
  );

  print(r.statusCode);
  print('----------------------------');
  print(r.headers);
  print('----------------------------');
  print(r.body);
  print('----------------------------');
}
