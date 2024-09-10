import FlutterMacOS
import Foundation

public class ZebraPrinterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example.zebra_printer", binaryMessenger: registrar.messenger)
    let instance = ZebraPrinterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "printZpl" {
      guard let args = call.arguments as? [String: Any],
            let zplCode = args["zplCode"] as? String,
            let scriptPath = args["scriptPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }

      let task = Process()
      task.launchPath = "/usr/bin/python3"
      task.arguments = [scriptPath, zplCode]

      task.launch()
      task.waitUntilExit()

      result("Printed ZPL successfully")
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}