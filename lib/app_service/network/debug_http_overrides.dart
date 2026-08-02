import 'dart:io';

/// Allows self-signed / LAN HTTPS certs in debug (API + SignalR WebSockets).
class DebugHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
