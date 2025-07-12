// lib/services/connectivity_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart'; // ✅ EKLENDİ

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // İnternet durumu stream'i
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  /// Connectivity servisini başlat
  void initialize() {
    _checkConnection();
    _startPeriodicCheck();
  }

  /// Periyodik bağlantı kontrolü başlat
  void _startPeriodicCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnection();
    });
  }

  /// İnternet bağlantısını kontrol et
  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectionStatus(isConnected);
    } catch (_) {
      _updateConnectionStatus(false);
    }
  }

  /// Bağlantı durumunu güncelle
  void _updateConnectionStatus(bool isConnected) {
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _connectionStatusController.add(_isOnline);
    }
  }

  /// Tek seferlik bağlantı kontrolü
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Servisi temizle
  void dispose() {
    _timer?.cancel();
    _connectionStatusController.close();
  }
}

// ✅ DÜZELTME: Mixin - Widget'larda kullanım için
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  void _initConnectivity() {
    final connectivityService = ConnectivityService();
    _isOnline = connectivityService.isOnline;

    _connectivitySubscription = connectivityService.connectionStatusStream.listen(
          (isOnline) {
        if (mounted) {
          setState(() {
            _isOnline = isOnline;
          });
          onConnectivityChanged(isOnline);
        }
      },
    );
  }

  /// Override this method to handle connectivity changes
  void onConnectivityChanged(bool isOnline) {
    if (isOnline) {
      onConnectionRestored();
    } else {
      onConnectionLost();
    }
  }

  /// Override this method for connection restored actions
  void onConnectionRestored() {
    // Default: Refresh data
    if (mounted) {
      setState(() {});
    }
  }

  /// Override this method for connection lost actions
  void onConnectionLost() {
    // Default: Show offline message
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}