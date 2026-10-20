class ApiConfig {
  /// Base URL for the NeighbourShield Django REST Framework backend.
  ///
  /// Network Configuration Guide:
  /// - Android Emulator: Use 'http://10.0.2.2:8000/api'
  /// - iOS Simulator / macOS / Windows / Web: Use 'http://127.0.0.1:8000/api'
  /// - Physical Phone (Wi-Fi): Use 'http://`YOUR_LOCAL_PC_IP`:8000/api'
  ///   (Ensure your PC and phone are on the same Wi-Fi, and Django is run with `0.0.0.0:8000`)
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
