import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
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

    final url = Uri.parse('https:dmf-shipping-app/process_order');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'order_id': orderId, 'display_image': true});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _statusMessage = 'Label generated successfully';
          _labelImageBase64 = responseData['label_image'];
          _labelImagePath = responseData['label_image_path'];
        });
      } else {
        final errorInfo = json.decode(response.body);
        setState(() {
          _statusMessage = 'Error processing order: ${errorInfo['error']}';
        });
      }
    } catch (e) {
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

    final url = Uri.parse('https://dmf-shipping-app/print_label');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'image_path': _labelImagePath});

    try {
      final response = await http.post(url, headers: headers, body: body);

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
                    child: Text(AppLocalizations.of(context)?.generateShippingLabel ?? 'Generate Shipping Label'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BulkLabelPrintScreen()),
                      );
                    },
                      child: Text(AppLocalizations.of(context)?.bulkLabelPrint ?? 'Bulk Label Print'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReprintLabelScreen()),
                      );
                    },
                      child: Text(AppLocalizations.of(context)?.reprintLabel ?? 'Reprint Label'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VoidLabelScreen()),
                      );
                    },
                      child: Text(AppLocalizations.of(context)?.voidLabel ?? 'Void Label'),
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

class VoidLabelScreen extends StatelessWidget {
  final TextEditingController _orderIdController = TextEditingController();

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
              controller: _orderIdController,
              decoration: InputDecoration(
                labelText: 'Input Order ID',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement void label functionality
              },
              child: Text('Void Label'),
            ),
          ],
        ),
      ),
    );
  }
}
