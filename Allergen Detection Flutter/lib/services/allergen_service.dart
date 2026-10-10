import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/allergen_model.dart';

class AllergenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'allergens';

  // Get all allergens as a stream
  Stream<List<AllergenModel>> getAllAllergens() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AllergenModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Add Allergen
  Future<void> addAllergen(AllergenModel allergen) async {
    try {
      // Use the provided ID or let Firestore generate one if handling differently
      await _firestore
          .collection(_collection)
          .doc(allergen.id)
          .set(allergen.toMap());
    } catch (e) {
      print('Error adding allergen: $e');
      rethrow;
    }
  }

  // Update Allergen
  Future<void> updateAllergen(AllergenModel allergen) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(allergen.id)
          .update(allergen.toMap());
    } catch (e) {
      print('Error updating allergen: $e');
      rethrow;
    }
  }

  // Delete Allergen
  Future<void> deleteAllergen(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting allergen: $e');
      rethrow;
    }
  }
}
