import Cocoa
import FlutterMacOS
import ZebraPrinterPlugin

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    ZebraPrinterPlugin.register(with: registrar(forPlugin: "ZebraPrinterPlugin"))
  }
}
