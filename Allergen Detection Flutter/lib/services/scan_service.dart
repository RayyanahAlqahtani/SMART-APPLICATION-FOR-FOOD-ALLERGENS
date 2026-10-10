import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scan_result_model.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'scans';

  // Get all scans as a stream
  Stream<List<ScanResultModel>> getAllScans() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ScanResultModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get scans for a specific user
  Stream<List<ScanResultModel>> getUserScans(String userId) {
    print('getUserScans called for userId: $userId');

    // Create the stream with orderBy
    final streamWithOrder = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Got ${snapshot.docs.length} scans for user $userId');
          return snapshot.docs.map((doc) {
            return ScanResultModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });

    // Also create a stream without orderBy as fallback
    final streamWithoutOrder = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('Got ${snapshot.docs.length} scans for user $userId (without orderBy)');
          return snapshot.docs.map((doc) {
            return ScanResultModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });

    // Try with orderBy, fall back to without orderBy if there's an error
    return streamWithOrder.handleError((error, stackTrace) {
      print('Error with orderBy query, falling back: $error');
      return streamWithoutOrder;
    });
  }

  // Add Scan
  Future<void> addScan(ScanResultModel scan) async {
    try {
      await _firestore.collection(_collection).doc(scan.id).set(scan.toMap());
    } catch (e) {
      print('Error adding scan: $e');
      rethrow;
    }
  }

  // Update Scan
  Future<void> updateScan(ScanResultModel scan) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(scan.id)
          .update(scan.toMap());
    } catch (e) {
      print('Error updating scan: $e');
      rethrow;
    }
  }

  // Delete Scan
  Future<void> deleteScan(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting scan: $e');
      rethrow;
    }
  }
}
