import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;

  // Public stream for components that prefer streams over listening to provider
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(results);
    } catch (_) {
      _isOnline = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _isConnected(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
        notifyListeners();
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(results);
      notifyListeners();
      return _isOnline;
    } catch (_) {
      return _isOnline;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }
}
