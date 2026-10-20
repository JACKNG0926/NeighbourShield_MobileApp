import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/session/app_session.dart';

void main() {
  final session = AppSession();
  runApp(NeighbourShieldApp(session: session));
}
