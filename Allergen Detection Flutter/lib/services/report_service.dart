import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';
  final _uuid = const Uuid();

  // ──────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────

  /// Submit a new report. Generates its own ID.
  Future<void> submitReport({
    required String userId,
    required String userName,
    required String title,
    required String description,
  }) async {
    final reportId = _uuid.v4();
    final report = ReportModel(
      reportId: reportId,
      userId: userId,
      userName: userName,
      title: title,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(_collection)
        .doc(reportId)
        .set(report.toMap());
  }

  // ──────────────────────────────────────────────
  // READ (Streams)
  // ──────────────────────────────────────────────

  /// Stream of ALL reports — for admin view.
  Stream<List<ReportModel>> getAllReports() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReportModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream of a single user's reports.
  Stream<List<ReportModel>> getUserReports(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReportModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream of total report count — used by Admin Dashboard stat card.
  Stream<int> getReportCount() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ──────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────

  /// Admin: update a report's status field.
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    await _firestore
        .collection(_collection)
        .doc(reportId)
        .update({'status': newStatus});
  }

  // ──────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────

  /// Admin: permanently delete a report.
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection(_collection).doc(reportId).delete();
  }
}
