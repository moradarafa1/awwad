import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits whether the device currently has a network connection. Used to hide
/// the suggested-solutions / video card when offline. Web-safe.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool isOnline(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);
  try {
    yield isOnline(await c.checkConnectivity());
  } catch (_) {
    yield true; // assume online if the check fails, to avoid hiding wrongly
  }
  yield* c.onConnectivityChanged.map(isOnline);
});
