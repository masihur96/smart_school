import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _controller.stream;

  Future<void> initialize() async {
    // Initial check
    final results = await _connectivity.checkConnectivity();
    _controller.add(_isConnected(results));

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_isConnected(results));
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    // true if any of the results is mobile or wifi
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi);
  }

  void dispose() {
    _controller.close();
  }
}
