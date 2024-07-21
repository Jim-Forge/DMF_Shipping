import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

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
  String? _labelImageBase64;

  Future<void> processOrder(String orderId) async {
    setState(() {
      _statusMessage = 'Processing...';
      _labelImageBase64 = null;
    });

    try {
      final url = Uri.parse('http://localhost:5001/process_order');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _statusMessage = 'Label generated successfully';
          _labelImageBase64 = responseData['label_image'];
        });
      } else {
        final errorInfo = json.decode(response.body);
        setState(() {
          _statusMessage = 'Error: ${errorInfo['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Network Error: ${e.toString()}';
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
      body: SingleChildScrollView(
        child: Padding(
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
              const SizedBox(height: 20),
              if (_labelImageBase64 != null && _labelImageBase64!.isNotEmpty)
                Image.memory(
                  base64Decode(_labelImageBase64!),
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                )
              else
                const Text('No label image available'),
            ],
          ),
        ),
      ),
    );
  }
}
