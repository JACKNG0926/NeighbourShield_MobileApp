import 'package:flutter/foundation.dart';

import '../../features/auth/models/user_session.dart';
import '../services/local_broadcast_sync_service.dart';
import 'user_role.dart';

/// In-memory holder for the currently authenticated backend profile.
/// Role changes must come from an authoritative Django response.
class AppSession extends ChangeNotifier {
  UserSession? _currentUser;

  UserSession? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get role => _currentUser?.role;

  void signIn(UserSession user) {
    _currentUser = user;
    LocalBroadcastSyncService.instance.start();
    notifyListeners();
  }

  /// Replaces the local profile with the latest profile returned by Django.
  /// This is used after submitting an opt-in or checking approval status.
  void updateCurrentUser(UserSession user) {
    _currentUser = user;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    LocalBroadcastSyncService.instance.stop();
    notifyListeners();
  }
}

