import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Davinci Shipping App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Davinci Shipping App'),
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
  String? _labelImagePath;

  Future<void> processOrder(String orderId) async {
  setState(() {
    _statusMessage = 'Processing...';
    _labelImageBase64 = null;
    _labelImagePath = null;
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
        _labelImagePath = responseData['label_image_path'];
      });
    } else {
      final errorInfo = json.decode(response.body)['error'];
      setState(() {
        _statusMessage = '''
Error in ${errorInfo['context']}
Order ID: ${errorInfo['order_id']}
Warehouse: ${errorInfo['warehouse']}
Details: ${errorInfo['error_details']}
''';
      });
    }
  } catch (e) {
    setState(() {
      if (e is http.ClientException) {
        _statusMessage = 'Network Error: ${e.message}';
      } else {
        _statusMessage = 'Error: ${e.toString()}';
      }
    });
  }
}

  Future<void> printLabel() async {
    if (_labelImagePath == null) {
      setState(() {
        _statusMessage = 'Error: No label image path available';
      });
      return;
    }

    try {
      final url = Uri.parse('http://localhost:5001/print_label');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'image_path': _labelImagePath}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Label printed successfully';
        });
      } else {
        final errorInfo = json.decode(response.body);
        setState(() {
          _statusMessage = 'Error printing label: ${errorInfo['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error printing label: ${e.toString()}';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                    child: const Text('Generate Shipping Label'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _orderIdController.clear();
                        _statusMessage = '';
                        _labelImageBase64 = null;
                        _labelImagePath = null;
                      });
                    },
                    child: const Text('Clear Data'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(_statusMessage),
              const SizedBox(height: 20),
              if (_labelImageBase64 != null)
                if (_labelImageBase64!.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.memory(
                        base64Decode(_labelImageBase64!),
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: printLabel,
                        child: const Text('Print Label'),
                      ),
                    ],
                  )
                else
                  const Text('No label image available')
            ],
          ),
        ),
      ),
    );
  }
}