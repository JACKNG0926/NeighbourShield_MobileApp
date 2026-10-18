import 'package:flutter/foundation.dart';

import '../../data/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool isLoading = false;
  String? errorMessage;

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    errorMessage = null;

    if (normalizedEmail.isEmpty || password.isEmpty) {
      errorMessage = 'Please enter your email and password.';
      notifyListeners();
      return null;
    }

    if (!normalizedEmail.contains('@')) {
      errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();

    try {
      return await _authRepository.signIn(
        email: normalizedEmail,
        password: password,
      );
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
