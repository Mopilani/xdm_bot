import 'package:http/http.dart' as http;

void main(List<String> args) {
  http.post(
    Uri.parse('http://167.172.167.245:8186/add'),
    headers: {
      'link':
          'https://dl3.downloadly.ir/Files/Elearning/Coursera_Foundations_of_Cybersecurity_2023_5_Downloadly.ir.rar'
    },
  );
}
