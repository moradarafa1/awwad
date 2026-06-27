// Web-safe facade. On mobile (dart:io) the real implementation is used; on web
// the no-op stub is used, so the web build never imports native plugins.
export 'notifications_stub.dart'
    if (dart.library.io) 'notifications_mobile.dart';
