import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ZebraPrinter {
  static const platform = MethodChannel('com.example.zebra_printer');

  static Future<void> printZpl(String zplCode) async {
    try {
      final String scriptPath = await _getScriptPath();
      final String result = await platform.invokeMethod('printZpl', {
        'zplCode': zplCode,
        'scriptPath': scriptPath,
      });
      print(result);
    } on PlatformException catch (e) {
      print("Failed to print ZPL: '${e.message}'.");
    }
  }

  static Future<String> _getScriptPath() async {
    final String fileName = Platform.isWindows ? 'print_zpl.bat' : 'print_zpl.sh';
    final directory = await getApplicationSupportDirectory();
    final path = '${directory.path}/$fileName';
    
    // Copy the script from assets to a writable location
    final ByteData data = await rootBundle.load('assets/scripts/$fileName');
    final List<int> bytes = data.buffer.asUint8List();
    await File(path).writeAsBytes(bytes);
    
    return path;
  }
}