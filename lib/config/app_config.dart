class AppConfig {
  static String get geminiApiKey {
    // TODO: Replace dengan API key baru dari Google Cloud Console
    // Go to: https://console.cloud.google.com/apis/credentials
    // Ganti key di bawah dengan yang baru
    const key = 'AIzaSyAl8oBkgF_gsvGB6ra5bo4_u3QfzUXDX28';
    return key;
  }

  static bool get isConfigured {
    return geminiApiKey.isNotEmpty &&
        geminiApiKey.startsWith('AIzaSy') &&
        !geminiApiKey.contains('YOUR_NEW');
  }
}
