import 'dart:io';
import 'package:allergen_detection_flutter/screens/user/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_api_service.dart';
import '../../services/scan_service.dart';
import '../../models/scan_result_model.dart';
import 'package:uuid/uuid.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
    }
  }

  void _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userModel = authProvider.currentUserModel;

      if (userModel == null) {
        throw Exception('User not logged in');
      }

      final allergens = userModel.allergenList;

      print('Starting AI analysis with allergens: $allergens');

      final aiService = AiApiService();
      final response = await aiService.analyzeImage(_image!, allergens);

      print('AI Response: $response');

      final isSafe = response['status'] == 'Safe';

      final detectedAllergensRaw =
          response['detected_allergens'] as List<dynamic>? ?? [];
      final detectedAllergens = detectedAllergensRaw.map((a) {
        return DetectedAllergen(
          word: a['word']?.toString() ?? '',
          category: a['category']?.toString() ?? 'Unknown',
          risk: a['risk']?.toString() ?? 'Low',
        );
      }).toList();

      final rawText = response['raw_text']?.toString() ?? '';

      // Relative path stored in Firestore — no base URL.
      // e.g. "/api/scan/image/scan_20250420_abc123.jpg"
      final imagePath = response['image_path']?.toString() ?? '';
      // Bare filename kept for backward compat
      final imageFilename = response['image_filename']?.toString() ?? '';

      final confidence = (response['confidence'] as num?)?.toDouble() ?? 1.0;

      final productName = _extractProductName(rawText);

      final uuid = const Uuid().v4();
      final newScan = ScanResultModel(
        id: uuid,
        productName: productName,
        imagePath: imagePath,
        imageFilename: imageFilename,
        isSafe: isSafe,
        detectedAllergens: detectedAllergens,
        confidence: confidence,
        date: DateTime.now(),
        extractedText: rawText,
        userId: userModel.userId,
      );

      print('Created scan: ${newScan.toString()}');

      final scanService = ScanService();
      await scanService.addScan(newScan);

      print('Scan saved to Firebase');

      if (mounted) {
        setState(() => _isProcessing = false);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(),
            settings: RouteSettings(arguments: newScan),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error in _analyzeImage: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: $e'),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _extractProductName(String rawText) {
    if (rawText.isEmpty) return 'Scanned Product';

    final lines = rawText.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          trimmed.length < 50 &&
          !trimmed.contains(':') &&
          !trimmed.contains('ingredients')) {
        return trimmed;
      }
    }
    return 'Scanned Product';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title:
            const Text('Scan Product', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: _image == null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(color: AppTheme.textPrimary),
                        DottedBorder(
                          color: AppTheme.primary,
                          strokeWidth: 3,
                          dashPattern: const [12, 8],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(20),
                          child: Container(
                            width: 280,
                            height: 380,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.document_scanner_outlined,
                                  size: 64,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Position ingredients\nlabel here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_image!, fit: BoxFit.contain),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: _isProcessing
                ? Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing ingredients...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _image == null
                            ? () => _getImage(ImageSource.gallery)
                            : _analyzeImage,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.image_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _image == null
                            ? () => _getImage(ImageSource.camera)
                            : _analyzeImage,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _image == null
                                ? Icons.camera_alt_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
