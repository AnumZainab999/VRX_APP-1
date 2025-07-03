import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'splash_screen.dart';
import 'error_dialog.dart'; // Import your ErrorDialog class here


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Add navigatorKey here
      debugShowCheckedModeBanner: false,
      home: ConnectivityWrapper(
        child: SplashScreen(),
      ),
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  // ignore: unused_field
  bool _isConnected = true;
  bool _hasShownNetworkError = false;
  late Connectivity _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final isNowConnected = result != ConnectivityResult.none;

    if (!isNowConnected && !_hasShownNetworkError) {
      _hasShownNetworkError = true;

      // ✅ Use global navigatorKey to get current context
      final currentContext = navigatorKey.currentContext ?? context;
      ErrorDialog.showByCode(currentContext, 'VRX-007');
    } else if (isNowConnected) {
      _hasShownNetworkError = false;
    }

    setState(() {
      _isConnected = isNowConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}