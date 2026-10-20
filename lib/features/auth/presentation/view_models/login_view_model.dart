import 'package:flutter/foundation.dart';

import '../../data/auth_repository.dart';
import '../../models/user_session.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool isLoading = false;
  String? errorMessage;

  Future<UserSession?> signIn({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    errorMessage = null;

    if (normalizedUsername.isEmpty || password.isEmpty) {
      errorMessage = 'Please enter your username and password.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();

    try {
      return await _authRepository.signIn(
        username: normalizedUsername,
        password: password,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
