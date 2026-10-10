import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/scan_result_model.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scan = ModalRoute.of(context)?.settings.arguments as ScanResultModel?;

    if (scan == null) {
      print('DEBUG: ResultScreen received null arguments');
      print('DEBUG: Route arguments: ${ModalRoute.of(context)?.settings.arguments}');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No scan data found')),
      );
    }

    print('DEBUG: ResultScreen received scan data for ${scan.productName}');

    final isSafe = scan.isSafe;
    final detectedAllergens = scan.detectedAllergens;
    final extractedText = scan.extractedText;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan Result'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushReplacementNamed(
              context, PathConstants.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scanned Image ────────────────────────────────────────
          if (scan.fullImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                scan.fullImageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_rounded,
                        size: 48, color: AppTheme.textLight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Safe / Unsafe status animation ──────────────────────
          TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSafe
                          ? AppTheme.safeGreen.withValues(alpha: 0.1)
                          : AppTheme.dangerRed.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      isSafe
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      size: 80,
                      color: isSafe ? AppTheme.safeGreen : AppTheme.dangerRed,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Text(
              isSafe ? 'Safe to Consume' : 'Allergens Detected!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isSafe ? AppTheme.safeGreen : AppTheme.dangerRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSafe
                  ? 'No allergens from your list were found'
                  : 'This product contains ingredients you should avoid',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (scan.productName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Product: ${scan.productName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
            if (scan.confidence > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(scan.confidence * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 32),

            if (!isSafe) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.dangerRed.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded,
                            color: AppTheme.dangerRed, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Detected Allergens',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...detectedAllergens.map((allergen) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRiskColor(allergen.risk).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allergen.word,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.dangerRed,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningOrange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      allergen.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.warningOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRiskColor(allergen.risk).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${allergen.risk} Risk',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getRiskColor(allergen.risk),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_snippet_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzed Ingredients',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: _buildHighlightedText(extractedText, detectedAllergens),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Scan Another Product'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, PathConstants.home, (route) => false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    Text('Go Home', style: TextStyle(color: AppTheme.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return AppTheme.dangerRed;
      case 'medium':
        return AppTheme.warningOrange;
      case 'low':
        return AppTheme.safeGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  List<TextSpan> _buildHighlightedText(String text, List<DetectedAllergen> allergens) {
    List<TextSpan> spans = [];
    final words = text.split(' ');
    final allergenWords = allergens.map((a) => a.word.toLowerCase()).toList();

    for (String word in words) {
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      bool isAllergen = allergenWords
          .any((a) => cleanWord.toLowerCase().contains(a));

      spans.add(TextSpan(
        text: '$word ',
        style: TextStyle(
          color: isAllergen ? AppTheme.dangerRed : AppTheme.textPrimary,
          fontWeight: isAllergen ? FontWeight.bold : FontWeight.normal,
          backgroundColor:
              isAllergen ? AppTheme.dangerRed.withValues(alpha: 0.1) : null,
        ),
      ));
    }
    return spans;
  }
}
