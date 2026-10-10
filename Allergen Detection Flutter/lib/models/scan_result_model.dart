import '../config/app_config.dart';

class DetectedAllergen {
  final String word;
  final String category;
  final String risk;

  const DetectedAllergen({
    required this.word,
    required this.category,
    required this.risk,
  });

  DetectedAllergen copyWith({
    String? word,
    String? category,
    String? risk,
  }) {
    return DetectedAllergen(
      word: word ?? this.word,
      category: category ?? this.category,
      risk: risk ?? this.risk,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'category': category,
      'risk': risk,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DetectedAllergen.fromMap(Map<String, dynamic> map) {
    return DetectedAllergen(
      word: map['word'] as String? ?? '',
      category: map['category'] as String? ?? 'Unknown',
      risk: map['risk'] as String? ?? 'Low',
    );
  }

  factory DetectedAllergen.fromJson(Map<String, dynamic> json) =>
      DetectedAllergen.fromMap(json);

  @override
  String toString() =>
      'DetectedAllergen(word: $word, category: $category, risk: $risk)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedAllergen &&
        other.word == word &&
        other.category == category &&
        other.risk == risk;
  }

  @override
  int get hashCode => word.hashCode ^ category.hashCode ^ risk.hashCode;
}

class ScanResultModel {
  final String id;
  final String productName;
  /// Relative path stored in Firestore, e.g. "/api/scan/image/scan_20250420_abc.jpg".
  /// Use [AppConfig.resolveImageUrl] to build the full display URL.
  final String imagePath;
  /// Bare filename — kept for backward compatibility with old Firestore docs.
  final String imageFilename;
  final bool isSafe;
  final List<DetectedAllergen> detectedAllergens;
  final double confidence;
  final DateTime date;
  final String extractedText;
  final String userId;

  const ScanResultModel({
    required this.id,
    required this.productName,
    this.imagePath = '',
    this.imageFilename = '',
    required this.isSafe,
    required this.detectedAllergens,
    required this.confidence,
    required this.date,
    required this.extractedText,
    required this.userId,
  });

  /// Returns the full URL for displaying this scan's image.
  /// Delegates to [AppConfig.resolveImageUrl] so the base URL is always
  /// sourced from [AppConfig.baseUrl] — no hardcoded IPs here.
  /// Falls back to building from [imageFilename] if [imagePath] is empty.
  String get fullImageUrl {
    if (imagePath.isNotEmpty) {
      return AppConfig.resolveImageUrl(imagePath);
    }
    if (imageFilename.isNotEmpty) {
      return AppConfig.resolveImageUrl(imageFilename);
    }
    return '';
  }

  // Legacy helper kept for source compatibility
  String getFullImageUrl(String baseUrl) =>
      imagePath.isNotEmpty ? '$baseUrl$imagePath' : (imageFilename.isNotEmpty ? '$baseUrl/api/scan/image/$imageFilename' : '');

  ScanResultModel copyWith({
    String? id,
    String? productName,
    String? imagePath,
    String? imageFilename,
    bool? isSafe,
    List<DetectedAllergen>? detectedAllergens,
    double? confidence,
    DateTime? date,
    String? extractedText,
    String? userId,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      imagePath: imagePath ?? this.imagePath,
      imageFilename: imageFilename ?? this.imageFilename,
      isSafe: isSafe ?? this.isSafe,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      confidence: confidence ?? this.confidence,
      date: date ?? this.date,
      extractedText: extractedText ?? this.extractedText,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'imagePath': imagePath,
      'imageFilename': imageFilename,
      'isSafe': isSafe,
      'detectedAllergens':
          detectedAllergens.map((a) => a.toMap()).toList(),
      'confidence': confidence,
      'date': date.toIso8601String(),
      'extractedText': extractedText,
      'userId': userId,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory ScanResultModel.fromMap(Map<String, dynamic> map) {
    return ScanResultModel(
      id: map['id'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      imageFilename: map['imageFilename'] as String? ?? '',
      isSafe: map['isSafe'] as bool? ?? true,
      detectedAllergens: (map['detectedAllergens'] as List<dynamic>?)
              ?.map((item) => DetectedAllergen.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      extractedText: map['extractedText'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
    );
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) =>
      ScanResultModel.fromMap(json);

  factory ScanResultModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    if (data['date'] != null) {
      if (data['date'].runtimeType.toString() == 'Timestamp') {
        parsedDate = data['date'].toDate();
      } else {
        parsedDate =
            DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
      }
    }

    List<DetectedAllergen> allergens = [];
    if (data['detectedAllergens'] != null) {
      if (data['detectedAllergens'] is List) {
        allergens = (data['detectedAllergens'] as List<dynamic>)
            .map((item) => DetectedAllergen.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return ScanResultModel(
      id: id,
      productName: data['productName'] as String? ?? '',
      imagePath: data['imagePath'] as String? ?? '',
      imageFilename: data['imageFilename'] as String? ?? '',
      isSafe: data['isSafe'] as bool? ?? true,
      detectedAllergens: allergens,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
      date: parsedDate,
      extractedText: data['extractedText'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'ScanResultModel(id: $id, productName: $productName, isSafe: $isSafe, detectedAllergens: $detectedAllergens, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScanResultModel &&
        other.id == id &&
        other.productName == productName &&
        other.imageFilename == imageFilename &&
        other.isSafe == isSafe &&
        other.confidence == confidence &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productName.hashCode ^
        imageFilename.hashCode ^
        isSafe.hashCode ^
        confidence.hashCode ^
        date.hashCode;
  }
}
