import 'package:http/http.dart' as http;

const String apiKey = 'maxvnvldI0N6BAwNpZNy6FnHQdgE4oPJ+zI3wtat0pnXH8+PCGH2jmKjw8ERzIpaNiGh62XLaH7JzRXWo4xhTw==';
const String apiUrl = 'http://api.kcisa.kr/openapi/API_CNV_053/request';

void main() async {
  try {
    var uri = Uri.parse(apiUrl).replace(queryParameters: {
      'serviceKey': apiKey,
      'numOfRows': '1',
      'pageNo': '1',
    });
    
    print('Requesting: $uri');
    var response = await http.get(uri);
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    
    if (response.statusCode == 200 && response.body.contains('<item>')) {
      print('\n✅ SUCCESS: API responded with data!');
    } else {
      print('\n❌ FAILURE: Check key or URL path.');
    }
  } catch (e) {
    print('Error: $e');
  }
}
