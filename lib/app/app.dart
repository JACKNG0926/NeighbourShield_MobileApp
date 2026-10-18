import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/login_page.dart';
import 'app_theme.dart';

class NeighbourShieldApp extends StatelessWidget {
  const NeighbourShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeighbourShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
