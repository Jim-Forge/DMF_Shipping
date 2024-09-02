import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:js' as js;

void main() {
  js.context.callMethod('eval', ['window.name = "ShippingApp";']);
  checkWindowName();
  runApp(const MyApp());
}

void checkWindowName() {
  js.context
      .callMethod('eval', ['console.log("Window name: " + window.name);']);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Generate Shipping Label',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Color.fromARGB(255, 181, 134, 33)),
              useMaterial3: true,
            ),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('es'),
            ],
            locale: languageProvider.currentLocale,
            home: LoginScreen(),
          );
        },
      ),
    );
  }
}

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = Locale('en');

  Locale get currentLocale => _currentLocale;

  void changeLocale(String languageCode) {
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;

  const CustomAppBar({Key? key, required this.title, this.showLogout = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(title),
      actions: [
        DropdownButton<String>(
          value:
              Provider.of<LanguageProvider>(context).currentLocale.languageCode,
          items: [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'es', child: Text('Español')),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              Provider.of<LanguageProvider>(context, listen: false)
                  .changeLocale(newValue);
            }
          },
        ),
        if (showLogout)
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // Login logic implementation
    if (_usernameController.text == 'admin' &&
        _passwordController.text == '123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'Davinci Shipping App')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          CustomAppBar(title: AppLocalizations.of(context)?.login ?? 'Login'),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context)?.loginUsername ?? 'Username',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.password ?? 'Password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: Text(AppLocalizations.of(context)?.login ?? 'Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void setupMessageListener() {
    html.window.onMessage.listen((event) {
      // Filter out messages from React Devtools
      if (event.data['source'] == 'react-devtools-content-script') {
        return; // Ignore this message
      }

      // Check if the message is an object and has the necessary properties
      if (event.data is Map<String, dynamic> &&
          event.data.containsKey('type') &&
          event.data.containsKey('source') &&
          event.data.containsKey('id')) {
        final messageType = event.data['type'] as String;
        final messageSource = event.data['source'] as String;
        final messageId = event.data['id'] as String;

        // Handle messages based on their type and source
        switch (messageType) {
          case 'triggerShippingAppButtonClick': // Example message type
            if (messageSource == 'extension') {
              // Handle button click triggered by the extension
              // ... your logic to process the order or perform other actions
              // You might also want to send a confirmation message back to the extension
            }
            break;
          // ... other message types you expect to handle
          default:
            print('Received unhandled message type: $messageType');
        }
      } else {
        print('Received invalid message format: ${event.data}');
      }
    });
  }

  final TextEditingController _orderIdController = TextEditingController();

  String _statusMessage = '';
  String? _labelImageBase64;
  String? _labelImagePath;

  Future<void> processOrder(String orderId) async {
    setState(() {
      _statusMessage = 'Processing order...';
      _labelImageBase64 = null;
      _labelImagePath = null;
    });

    final url = Uri.parse(
        'https://shipping-app-server-c48d90c52e59.herokuapp.com/process_order');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'order_id': orderId, 'display_image': true});

    try {
      final response = await http.post(url, headers: headers, body: body);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          try {
            final responseData = json.decode(response.body);
            print('Decoded JSON response: $responseData');
            setState(() {
              _statusMessage = 'Label generated successfully';
              _labelImageBase64 = responseData['label_image'];
              _labelImagePath = responseData['label_image_path'];
            });
          } catch (e) {
            print('Error decoding JSON: $e');
            setState(() {
              _statusMessage = 'Error processing order: Invalid JSON response';
            });
          }
        } else if (contentType != null && contentType.contains('text/html')) {
          print('Received HTML response instead of JSON');
          final decodedBody = utf8.decode(response.bodyBytes);
          print('Decoded HTML response body: $decodedBody');
          setState(() {
            _statusMessage = 'Error: Received HTML response instead of JSON';
          });
        } else {
          print('Unexpected content type: $contentType');
          setState(() {
            _statusMessage = 'Error: Unexpected response format';
          });
        }
      } else {
        print('Error response body: ${response.body}');
        setState(() {
          _statusMessage = 'Error processing order: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Network or other error: $e');
      setState(() {
        _statusMessage = 'Error processing order: ${e.toString()}';
      });
    }
  }

  Future<void> printLabel() async {
    if (_labelImagePath == null) {
      setState(() {
        _statusMessage = 'No label available to print';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Printing label...';
    });

    final url = Uri.parse(
        'https://shipping-app-server-c48d90c52e59.herokuapp.com/print_label');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'image_path': _labelImagePath});

    try {
      final response = await http.post(url, headers: headers, body: body);
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('Decoded JSON response: $responseData');
          setState(() {
            _statusMessage = 'Label printed successfully';
          });
        } catch (e) {
          print('Error decoding JSON: $e');
          print('Failed to decode response body: ${response.body}');
          setState(() {
            _statusMessage = 'Error printing label: Invalid JSON response';
          });
        }
      } else {
        if (response.headers['content-type']?.contains('text/html') == true) {
          print('Received HTML response instead of JSON');
          print('HTML response body: ${response.body}');
          setState(() {
            _statusMessage = 'Error printing label: Received HTML response';
          });
        } else {
          try {
            final errorInfo = json.decode(response.body);
            print('Decoded error JSON: $errorInfo');
            setState(() {
              _statusMessage = 'Error printing label: ${errorInfo['error']}';
            });
          } catch (e) {
            print('Error decoding error JSON: $e');
            print('Failed to decode error response: ${response.body}');
            setState(() {
              _statusMessage = 'Error printing label: ${response.body}';
            });
          }
        }
      }
    } catch (e) {
      print('Network or other error: $e');
      setState(() {
        _statusMessage = 'Error printing label: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)?.generateShippingLabel ??
              'Generate Shipping Label',
          showLogout: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _orderIdController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.orderId ?? 'Order ID',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    key: const ValueKey('generateShippingLabelButton'),
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
                    child: Text(
                        AppLocalizations.of(context)?.generateShippingLabel ??
                            'Generate Shipping Label'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BulkLabelPrintScreen()),
                      );
                    },
                    child: Text(AppLocalizations.of(context)?.bulkLabelPrint ??
                        'Bulk Label Print'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReprintLabelScreen()),
                      );
                    },
                    child: Text(AppLocalizations.of(context)?.reprintLabel ??
                        'Reprint Label'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VoidLabelScreen()),
                      );
                    },
                    child: Text(AppLocalizations.of(context)?.voidLabel ??
                        'Void Label'),
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfigurationScreen(
                            initialDisplayLabelImage:
                                true, // Set an initial value
                            onDisplayLabelImageChanged: (value) {
                              // Handle the change here, e.g., update a global state
                              print('Display label image changed to: $value');
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)?.configuration ??
                        'Configuration'),
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
                        Uint8List.fromList(base64Decode(_labelImageBase64!)),
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: printLabel,
                            child: const Text('Print Label'),
                          ),
                          const SizedBox(height: 10),
                          Text('Order ID: ${_orderIdController.text}'),
                        ],
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

class BulkLabelPrintScreen extends StatelessWidget {
  final TextEditingController _orderIdsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Bulk Label Print', showLogout: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _orderIdsController,
              decoration: InputDecoration(
                labelText: 'Input Order IDs',
                hintText: 'Enter order IDs separated by commas',
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement generate shipping labels functionality
              },
              child: Text('Generate Shipping Labels'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReprintLabelScreen extends StatelessWidget {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _trackingNumberController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Reprint Label', showLogout: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _orderIdController,
              decoration: InputDecoration(
                labelText: 'Input Order ID',
              ),
            ),
            SizedBox(height: 10),
            Text('OR', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _trackingNumberController,
              decoration: InputDecoration(
                labelText: 'Input Tracking Number',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement reprint label functionality
              },
              child: Text('Reprint Label'),
            ),
          ],
        ),
      ),
    );
  }
}

class VoidLabelScreen extends StatefulWidget {
  @override
  _VoidLabelScreenState createState() => _VoidLabelScreenState();
}

class _VoidLabelScreenState extends State<VoidLabelScreen> {
  final TextEditingController _shipiumLabelIdController =
      TextEditingController();
  final TextEditingController _carrierTrackingIdController =
      TextEditingController();
  String _statusMessage = '';

  Future<void> _voidLabel() async {
    final url = Uri.parse(
        'https://shipping-app-server-c48d90c52e59.herokuapp.com/void_label');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'shipium_label_id': _shipiumLabelIdController.text,
        'carrier_tracking_id': _carrierTrackingIdController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _statusMessage = 'Label voided successfully';
      });
    } else {
      setState(() {
        _statusMessage = 'Error voiding label: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Void Label', showLogout: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _shipiumLabelIdController,
              decoration: InputDecoration(
                labelText: 'Shipium Label ID',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _carrierTrackingIdController,
              decoration: InputDecoration(
                labelText: 'Carrier Tracking ID',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _voidLabel,
              child: Text('Void Label'),
            ),
            SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}

class ConfigurationScreen extends StatefulWidget {
  final bool initialDisplayLabelImage;
  final Function(bool) onDisplayLabelImageChanged;

  const ConfigurationScreen({
    Key? key,
    required this.initialDisplayLabelImage,
    required this.onDisplayLabelImageChanged,
  }) : super(key: key);

  @override
  _ConfigurationScreenState createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  late bool _displayLabelImage;

  @override
  void initState() {
    super.initState();
    _displayLabelImage = widget.initialDisplayLabelImage;
    _loadDisplayLabelImageSetting();
  }

  Future<void> _loadDisplayLabelImageSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayLabelImage = prefs.getBool('displayLabelImage') ?? _displayLabelImage;
    });
  }

  Future<void> _saveDisplayLabelImageSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('displayLabelImage', value);
    widget.onDisplayLabelImageChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Configuration', showLogout: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display Label Image in UI'),
            DropdownButton<bool>(
              value: _displayLabelImage,
              onChanged: (bool? newValue) {
                if (newValue != null) {
                  setState(() {
                    _displayLabelImage = newValue;
                  });
                  _saveDisplayLabelImageSetting(newValue);
                }
              },
              items: [
                DropdownMenuItem(value: true, child: Text('Yes')),
                DropdownMenuItem(value: false, child: Text('No')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
