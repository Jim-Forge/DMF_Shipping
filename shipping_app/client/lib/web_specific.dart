// lib/web_specific.dart
import 'dart:html';

void setupMessageListener(Function(String) onMessageReceived) {
  window.onMessage.listen((event) {
    if (event.data is Map) {
      if (event.data['type'] == 'FROM_PAGE') {
        onMessageReceived(event.data['orderId']);
      } else if (event.data['action'] == 'setOrderId') {
        onMessageReceived(event.data['orderId']);
      }
    }
  });
}