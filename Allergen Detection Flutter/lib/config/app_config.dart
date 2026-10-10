/// Central configuration for the app.
/// All network calls and image resolution should go through here.
class AppConfig {

  static const String baseUrl = 'http://192.168.1.8:5000';

  // ── Image helpers ────────────────────────────────────────────────

  static String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/')) return '$baseUrl$imagePath';
    return '$baseUrl/api/scan/image/$imagePath';
  }

  // ── API Endpoints ────────────────────────────────────────────────
  static const String apiScan        = '$baseUrl/api/scan';
  static const String apiImages      = '$baseUrl/api/images';
  static const String apiAllergens   = '$baseUrl/api/allergens';
}
