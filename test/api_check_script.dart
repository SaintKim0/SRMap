import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

// Copy params from .env (Manual for this script)
const String apiKey = 'maxvnvldI0N6BAwNpZNy6FnHQdgE4oPJ+zI3wtat0pnXH8+PCGH2jmKjw8ERzIpaNiGh62XLaH7JzRXWo4xhTw==';
const String apiUrl = 'http://api.kcisa.kr/openapi/API_CNV_053/request';

void main() async {
  try {
    // Attempt 1: Decoding Key (Standard Http)
    var uri = Uri.parse(apiUrl).replace(queryParameters: {
      'serviceKey': apiKey,
      'numOfRows': '1',
      'pageNo': '1',
    });
    
    print('Requesting: $uri');
    var response = await http.get(uri);
    
    if (response.statusCode == 200) {
      print('Response Status: 200');
      print('Body Preview: ${response.body.substring(0, 200)}...');
      
      final document = XmlDocument.parse(response.body);
      final item = document.findAllElements('item').firstOrNull;
      
      if (item != null) {
        print('\n--- XML Item Fields ---');
        item.children.where((n) => n is XmlElement).forEach((node) {
          print('${(node as XmlElement).name.local}: ${node.innerText}');
        });
      } else {
        print('No items found.');
      }
    } else {
      print('Error: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
