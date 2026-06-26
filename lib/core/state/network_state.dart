// Shared state object used across app features.
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkState {
  static final NetworkState instance = NetworkState._internal();
  NetworkState._internal();

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  void initialize() {
    Connectivity().checkConnectivity().then(_updateConnectionState);
    Connectivity().onConnectivityChanged.listen(_updateConnectionState);
  }

  void _updateConnectionState(List<ConnectivityResult> result) {
    if (result.every((element) => element == ConnectivityResult.none)) {
      isOnlineNotifier.value = false;
    } else {
      isOnlineNotifier.value = true;
    }
  }
}
