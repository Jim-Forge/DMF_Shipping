import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderProcessingPage extends StatefulWidget {
  @override
  _OrderProcessingPageState createState() => _OrderProcessingPageState();
}

class _OrderProcessingPageState extends State<OrderProcessingPage> {
  String? labelImageBase64;

  Future<void> processOrder(String orderId) async {
    final response = await http.post(
      Uri.parse('http://your_server_ip:5001/process_order'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'order_id': orderId,
        'display_image': false, // We'll display in Flutter instead
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        labelImageBase64 = data['label_image_base64'];
      });
    } else {
      throw Exception('Failed to process order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Processing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => processOrder('your_order_id_here'),
              child: Text('Process Order'),
            ),
            SizedBox(height: 20),
            if (labelImageBase64 != null)
              Image.memory(
                base64Decode(labelImageBase64!),
                width: 300,
                height: 300,
              ),
          ],
        ),
      ),
    );
  }
}