// Provides shared service logic for network info.

import 'package:connectivity_plus/connectivity_plus.dart';

/// Defines behavior for network info.
abstract class NetworkInfo {
  /// Handles the is connected operation.
  Future<bool> get isConnected;
}

/// Defines behavior for network info impl.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  /// Creates a network info impl instance.
  NetworkInfoImpl({required this.connectivity});

  /// Handles the is connected operation.
  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
