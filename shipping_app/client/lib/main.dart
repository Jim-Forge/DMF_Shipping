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
      title: 'Shipping App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Shipping App'),
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

  Future<void> processOrder(String orderId) async {
    setState(() {
      _statusMessage = 'Processing...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/process_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId}),
      );

      if (response.statusCode == 200) {
        final labelInfo = json.decode(response.body);
        setState(() {
          _statusMessage =
              'Label generated successfully. Carrier: ${labelInfo['carrier']}, Tracking Number: ${labelInfo['tracking_number']}';
        });
      } else {
        final errorInfo = json.decode(response.body);
        setState(() {
          _statusMessage = 'Error: ${errorInfo['error']}';
        });
      }
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
                  processOrder(orderId);
                } else {
                  setState(() {
                    _statusMessage = 'Please enter an Order ID';
                  });
                }
              },
              child: const Text('Process Order'),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
