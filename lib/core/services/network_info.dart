// Provides shared service logic for network info.

import 'package:connectivity_plus/connectivity_plus.dart';

/// Defines behavior for network info.
/// Abstract interface for checking network connectivity.
abstract class NetworkInfo {
  /// Handles the is connected operation.
  /// Returns true if the device has an active internet connection.
  Future<bool> get isConnected;
}

/// Defines behavior for network info impl.
/// Implementation of NetworkInfo using Connectivity package.
class NetworkInfoImpl implements NetworkInfo {
  /// Connectivity instance for checking network status.
  final Connectivity connectivity;

  /// Creates a network info impl instance.
  NetworkInfoImpl({required this.connectivity});

  /// Handles the is connected operation.
  @override
  Future<bool> get isConnected async {
    // Check the current connectivity status.
    final result = await connectivity.checkConnectivity();

    // Return true if any connectivity result is not 'none'.
    return !result.contains(ConnectivityResult.none);
  }
}