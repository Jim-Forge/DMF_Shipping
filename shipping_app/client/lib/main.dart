import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipping Label Printer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Shipping Label Printer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _orderIdController = TextEditingController();
  String _statusMessage = '';

  Future<void> printLabel(String orderId) async {
    try {
      // Get order info
      final orderInfoResponse = await http.get(Uri.parse('http://your-server-ip:5000/get_order_info?order_id=$orderId'));
      if (orderInfoResponse.statusCode != 200) {
        throw Exception('Failed to load order info');
      }
      final orderInfo = json.decode(orderInfoResponse.body);

      // Generate shipping label
      final labelResponse = await http.post(
        Uri.parse('http://your-server-ip:5000/generate_label'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderInfo),
      );
      if (labelResponse.statusCode != 200) {
        throw Exception('Failed to generate label');
      }
      final labelInfo = json.decode(labelResponse.body);

      // Print label
      final printResponse = await http.post(
        Uri.parse('http://your-server-ip:5000/print_label'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'label_url': labelInfo['label_url']}),
      );
      if (printResponse.statusCode != 200) {
        throw Exception('Failed to print label');
      }

      setState(() {
        _statusMessage = 'Label printed successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Order ID',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final orderId = _orderIdController.text;
                if (orderId.isNotEmpty) {
                  printLabel(orderId);
                } else {
                  setState(() {
                    _statusMessage = 'Please enter an Order ID';
                  });
                }
              },
              child: const Text('Print Shipping Label'),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}