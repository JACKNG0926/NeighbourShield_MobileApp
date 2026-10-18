class AuthRepository {
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    // DEMO ONLY:
    // Simulate an API request.
    // Replace this with the Django REST API later.

    await Future.delayed(const Duration(milliseconds: 500));

    return email;
  }
}
