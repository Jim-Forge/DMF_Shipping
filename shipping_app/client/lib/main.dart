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
import 'dart:developer' as developer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File, Platform;

void main() {
  js.context.callMethod('eval', ['window.name = "ShippingApp";']);
  checkWindowName();
  runApp(const MyApp());
}

void checkWindowName() {
  js.context
      .callMethod('eval', ['console.log("Window name: " + window.name);']);
}

void sendPrintJob(String zplData) {
  html.window.postMessage({'type': 'ZEBRA_PRINT', 'data': zplData}, '*');
}

class ZebraPrinter {
  static const platform = MethodChannel('com.example.zebra_printer');

  Future<void> printZpl(String zplCode) async {
    try {
      final String scriptPath = await getScriptPath('print_to_zebra.py');
      final String result = await platform.invokeMethod('printZpl', {
        'zplCode': zplCode,
        'scriptPath': scriptPath,
      });
      print(result);
    } on PlatformException catch (e) {
      print("Failed to print ZPL: '${e.message}'.");
    }
  }

  Future<String> getScriptPath(String scriptName) async {
    final directory = await getApplicationDocumentsDirectory();
    final scriptFile = File('${directory.path}/$scriptName');
    if (!scriptFile.existsSync()) {
      final byteData = await rootBundle.load('assets/scripts/$scriptName');
      await scriptFile.writeAsBytes(byteData.buffer.asUint8List());
    }
    return scriptFile.path;
  }
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

  bool _hasTriedToGenerateLabel = false;

  Future<void> printToZebraPrinter(String zplCode) async {
    final zebraPrinter = ZebraPrinter();
    try {
      await zebraPrinter.printZpl(zplCode);
      setState(() {
        _statusMessage = 'Label sent to Zebra printer successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sending label to Zebra printer: $e';
      });
    }
  }

Future<void> processOrder(String orderId) async {
  setState(() {
    _statusMessage = 'Processing order...';
    _labelImageBase64 = null;
    _labelImagePath = null;
    _hasTriedToGenerateLabel = false;
  });

  final prefs = await SharedPreferences.getInstance();
  final selectedPrinterName = prefs.getString('selectedPrinter');

  try {
    final response = await http.post(
      Uri.parse('https://shipping-app-server-c48d90c52e59.herokuapp.com/create_shipment_label'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'order_id': orderId,
        'printer_id': selectedPrinterName ?? '',
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Decoded JSON response: $responseData');
      setState(() {
        _statusMessage = 'Label generated successfully';
        _labelImageBase64 = responseData['label_info']['label_image'];
        print('Label Image Base64 set: ${_labelImageBase64?.substring(0, 30)}...');
        _labelImagePath = responseData['label_image_path'];
        _hasTriedToGenerateLabel = true;
        print('Label Image Base64 in setState: $_labelImageBase64');
        print('Label Image Path in setState: $_labelImagePath');
      });
      await printLabel();
    } else {
      print('Error response body: ${response.body}');
      setState(() {
        _statusMessage = 'Error processing order: ${response.statusCode}';
        _hasTriedToGenerateLabel = true;
      });
    }
  } catch (e) {
    print('Network or other error: $e');
    setState(() {
      _statusMessage = 'Error processing order: ${e.toString()}';
      _hasTriedToGenerateLabel = true;
    });
  }
}

  Future<void> printLabel() async {
    if (_labelImageBase64 == null) {
      setState(() {
        _statusMessage = 'No label available to print';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Printing label...';
    });

    try {
      final decodedBytes = base64Decode(_labelImageBase64!);
      final pdfDocument = pw.Document();
      final image = pw.MemoryImage(decodedBytes);

      pdfDocument.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final selectedPrinterName = prefs.getString('selectedPrinter');

      if (selectedPrinterName != null) {
        final printers = await Printing.listPrinters();
        final selectedPrinter = printers.firstWhere(
          (printer) => printer.name == selectedPrinterName,
          orElse: () => printers.isNotEmpty
              ? printers.first
              : throw Exception('No printers available'),
        );

        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (PdfPageFormat format) async => pdfDocument.save(),
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfDocument.save(),
        );
      }

      setState(() {
        _statusMessage = 'Label printed successfully';
      });
    } catch (e) {
      print('Error printing label: $e');
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
                            initialDisplayLabelImage: true,
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
              // Builder(
              //   builder: (context) {
              //     print(
              //         'Building image widget. _labelImageBase64 length: ${_labelImageBase64?.length}');
              //     print(
              //         '_labelImageBase64: ${_labelImageBase64?.substring(0, 30)}...'); // Log the first 30 characters
              //     print('Render');
              //     if (_labelImageBase64 != null &&
              //         _labelImageBase64!.isNotEmpty) {
              //       developer.log('Attempting to render label image');
              //       try {
              //         final decodedBytes = base64Decode(_labelImageBase64!);
              //         print('Decoded bytes length: ${decodedBytes.length}');
              //         if (decodedBytes.isNotEmpty) {
              //           return Column(
              //             children: [
              //               Image.memory(
              //                 Uint8List.fromList(decodedBytes),
              //                 width: 300,
              //                 height: 300,
              //                 fit: BoxFit.contain,
              //                 errorBuilder: (context, error, stackTrace) {
              //                   print(
              //                       'Error creating Image.memory widget: $error');
              //                   return Column(
              //                     children: [
              //                       Icon(Icons.error,
              //                           color: Colors.red, size: 50),
              //                       SizedBox(height: 10),
              //                       Text(
              //                         'Error displaying image: Invalid image format',
              //                         style: TextStyle(color: Colors.red),
              //                         textAlign: TextAlign.center,
              //                       ),
              //                     ],
              //                   );
              //                 },
              //               ),
              //               const SizedBox(height: 10),
              //               Text('Order ID: ${_orderIdController.text}'),
              //               const SizedBox(height: 10),
              //               ElevatedButton(
              //                 onPressed: printLabel,
              //                 child: const Text('Print Label'),
              //               ),
              //             ],
              //           );
              //         } else {
              //           developer.log('Decoded bytes are empty');
              //           return const Text(
              //               'Error rendering label image: Decoded bytes are empty');
              //         }
              //       } catch (e) {
              //         developer.log('Error decoding base64 image: $e');
              //         return const Text('Error rendering label image');
              //       }
              //     } else if (_hasTriedToGenerateLabel) {
              //       developer.log('No label image available');
              //       return const Text('No label image available');
              //     } else {
              //       return Container(); // Return an empty container if no status message is set
              //     }
              //   },
              // )
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
  bool _displayLabelImage = false;
  List<Printer> _availablePrinters = [];
  Printer? _selectedPrinter;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _displayLabelImage = widget.initialDisplayLabelImage;
    _fetchAvailablePrinters().then((_) => _loadPreferences());
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayLabelImage =
          _prefs.getBool('displayLabelImage') ?? _displayLabelImage;
      String? selectedPrinterName = _prefs.getString('selectedPrinter');
      if (selectedPrinterName != null) {
        _selectedPrinter = _availablePrinters.firstWhere(
          (printer) => printer.name == selectedPrinterName,
          orElse: () => Printer(name: selectedPrinterName, url: ''),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _saveConfiguration();
  }

  Future<void> _saveConfiguration() async {
    await _prefs.setBool('displayLabelImage', _displayLabelImage);
    if (_selectedPrinter != null) {
      await _prefs.setString('selectedPrinter', _selectedPrinter!.name);
    }
  }

  Future<void> _fetchAvailablePrinters() async {
    if (_availablePrinters.isNotEmpty) {
      return; // Don't fetch if we already have printers
    }

    if (kIsWeb) {
      await _fetchPrintersFromServer();
    } else {
      try {
        final printers = await Printing.listPrinters();
        setState(() {
          _availablePrinters = printers;
          if (_selectedPrinter == null && _availablePrinters.isNotEmpty) {
            _selectedPrinter = _availablePrinters.first;
          }
        });
      } catch (e) {
        print('Error fetching printers: $e');
      }
    }
  }

  Future<void> _fetchPrintersFromServer() async {
    try {
      final response = await http.get(Uri.parse(
          'https://shipping-app-server-c48d90c52e59.herokuapp.com/get_printers'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _availablePrinters = data
              .map((printer) {
                if (printer is Map<String, dynamic> &&
                    printer.containsKey('name')) {
                  return Printer(name: printer['name'], url: '');
                } else {
                  print('Invalid printer data: $printer');
                  return null;
                }
              })
              .whereType<Printer>()
              .toList();

          if (_availablePrinters.isNotEmpty) {
            _selectedPrinter = _availablePrinters.first;
          }
        });
        print(
            'Fetched printers: ${_availablePrinters.map((p) => p.name).toList()}');
      } else {
        print('Error fetching printers from server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching printers from server: $e');
    }
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
            SwitchListTile(
              title: Text('Display Label Image'),
              value: _displayLabelImage,
              onChanged: (bool value) {
                setState(() {
                  _displayLabelImage = value;
                });
                _saveConfiguration(); // Save when changed
                widget.onDisplayLabelImageChanged(value); // Notify parent
              },
            ),
            SizedBox(height: 20),
            Text('Select Printer:'),
            DropdownButton<Printer>(
              value: _selectedPrinter,
              isExpanded: true,
              items: _availablePrinters.map((Printer printer) {
                return DropdownMenuItem<Printer>(
                  value: printer,
                  child: Text(printer.name),
                );
              }).toList(),
              onChanged: (Printer? newValue) {
                setState(() {
                  _selectedPrinter = newValue;
                });
                _saveConfiguration(); // Save when changed
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePrinterFetchError() {
    setState(() {
      _availablePrinters = [Printer(name: 'Default Printer', url: '')];
      _selectedPrinter = _availablePrinters.first;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Printer selection is limited. Using default printer.')),
    );
  }
}
