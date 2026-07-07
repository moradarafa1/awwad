// Shared classifier for network-shaped failures. Used by every screen that
// surfaces auth/sync errors so the substring list can't drift between copies.
bool isNetworkError(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('sockete') || // SocketException
      s.contains('failed host lookup') ||
      s.contains('clientexception') ||
      s.contains('retryablefetch') || // AuthRetryableFetchException
      s.contains('timeout') ||
      s.contains('connection');
}
