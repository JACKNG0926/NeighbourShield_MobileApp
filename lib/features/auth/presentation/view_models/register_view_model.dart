import 'package:flutter/foundation.dart';

import '../../data/auth_repository.dart';
import '../../models/user_session.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool isLoading = false;
  String? errorMessage;

  Future<UserSession?> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String password,
  }) async {
    errorMessage = null;

    if (username.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      errorMessage = 'Username, email, and password are required.';
      notifyListeners();
      return null;
    }

    if (!email.trim().contains('@')) {
      errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();

    try {
      return await _authRepository.register(
        username: username.trim(),
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
        address: address.trim(),
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
