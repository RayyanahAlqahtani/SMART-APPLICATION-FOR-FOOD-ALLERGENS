import 'package:cloud_firestore/cloud_firestore.dart';

/// Status constants for a user report.
class ReportStatus {
  static const String pending = 'pending';
  static const String reviewed = 'reviewed';
  static const String resolved = 'resolved';

  /// All possible statuses for iteration.
  static const List<String> all = [pending, reviewed, resolved];
}

class ReportModel {
  final String reportId;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String status; // See [ReportStatus]
  final DateTime createdAt;

  const ReportModel({
    required this.reportId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  ReportModel copyWith({
    String? reportId,
    String? userId,
    String? userName,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      final raw = data['createdAt'];
      if (raw is Timestamp) {
        parsedDate = raw.toDate();
      } else if (raw is String) {
        parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
      }
    }

    return ReportModel(
      reportId: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Unknown User',
      title: data['title'] as String? ?? '(No Title)',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? ReportStatus.pending,
      createdAt: parsedDate,
    );
  }

  @override
  String toString() =>
      'ReportModel(reportId: $reportId, userId: $userId, title: $title, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportModel &&
          other.reportId == reportId &&
          other.status == status;

  @override
  int get hashCode => reportId.hashCode ^ status.hashCode;
}
