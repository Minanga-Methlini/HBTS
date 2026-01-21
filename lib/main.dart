import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'auth/auth_gate.dart';
import 'state/notification_store.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => NotificationStore()
        ..refresh()
        ..startPolling(),
      child: const HBTSApp(),
    ),
  );
}

class HBTSApp extends StatelessWidget {
  const HBTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HBTS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ✅ enables Navigator.pushNamed(...)
      onGenerateRoute: AppRoutes.onGenerate,

      // ✅ startup auth redirect happens inside AuthGate
      home: const AuthGate(),
    );
  }
}
