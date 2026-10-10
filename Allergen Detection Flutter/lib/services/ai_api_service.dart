import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AiApiService {
  /// Sends [image] to the AI scan endpoint along with the user's [allergens].
  ///
  /// The server saves the image and returns:
  ///   - The analysis result (ingredients, detected allergens, isSafe, etc.)
  ///   - `image_path`  — a RELATIVE path like "/api/scan/image/<filename>"
  ///                     stored in Firestore as-is (no base URL).
  ///   - `image_filename` — the bare filename (kept for backward compat).
  ///
  /// Call [AppConfig.resolveImageUrl] when displaying the image.
  Future<Map<String, dynamic>> analyzeImage(
      File image, List<String> allergens) async {
    final uri = Uri.parse(AppConfig.apiScan);
    var request = http.MultipartRequest('POST', uri);

    // Attach image
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
    ));

    // Attach user allergens as comma-separated string
    if (allergens.isNotEmpty) {
      request.fields['allergens'] = allergens.join(',');
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // `image_path` is already a relative path — store it as-is in Firestore
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to analyze image');
      }
    } catch (e) {
      throw Exception('Could not connect to the AI service: $e');
    }
  }

  /// Standalone image upload — useful when no scan analysis is needed.
  /// Returns the relative [image_path] to store in Firestore.
  Future<String> uploadImage(File image) async {
    final uri = Uri.parse('${AppConfig.apiImages}/upload');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['image_path'] as String? ?? '';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Could not upload image: $e');
    }
  }
}
