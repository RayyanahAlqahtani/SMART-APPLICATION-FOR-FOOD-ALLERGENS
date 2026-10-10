// import '../models/user_model.dart';
// import '../models/allergen_model.dart';
// import '../models/scan_result_model.dart';

// class MockDatabase {
//   // Mock Current User
//   static UserModel currentUser = UserModel(
//     userId: 'u123',
//     name: 'User',
//     email: 'user@example.com',
//     role: 'user',
//     allergenList: ['Peanuts', 'Gluten'],
//     createdAt: DateTime.now().subtract(const Duration(days: 30)),
//   );

//   static UserModel adminUser = UserModel(
//     userId: 'a100',
//     name: 'Admin',
//     email: 'admin@admin.com',
//     role: 'admin',
//     allergenList: [],
//     createdAt: DateTime.now().subtract(const Duration(days: 365)),
//   );

//   // Mock Content
//   static final List<AllergenModel> commonAllergens = [
//     AllergenModel(id: 'a1', name: 'Peanuts', category: 'Nuts'),
//     AllergenModel(id: 'a2', name: 'Milk', category: 'Dairy'),
//     AllergenModel(id: 'a3', name: 'Eggs', category: 'Animal Product'),
//     AllergenModel(id: 'a4', name: 'Gluten', category: 'Cereal'),
//     AllergenModel(id: 'a5', name: 'Soy', category: 'Legume'),
//     AllergenModel(id: 'a6', name: 'Shellfish', category: 'Seafood'),
//     AllergenModel(id: 'a7', name: 'Tree Nuts', category: 'Nuts'),
//     AllergenModel(id: 'a8', name: 'Fish', category: 'Seafood'),
//   ];

//   static final List<ScanResultModel> scanHistory = [
//     ScanResultModel(
//       id: 's1',
//       productName: 'Choco Delight Bar',
//       imageUrl: 'https://via.placeholder.com/150',
//       isSafe: false,
//       detectedAllergens: ['Peanuts', 'Milk'],
//       confidence: 0.98,
//       date: DateTime.now().subtract(const Duration(hours: 2)),
//     ),
//     ScanResultModel(
//       id: 's2',
//       productName: 'Organic Apple Chips',
//       imageUrl: 'https://via.placeholder.com/150',
//       isSafe: true,
//       detectedAllergens: [],
//       confidence: 0.99,
//       date: DateTime.now().subtract(const Duration(days: 1)),
//     ),
//     ScanResultModel(
//       id: 's3',
//       productName: 'Wheat Crackers',
//       imageUrl: 'https://via.placeholder.com/150',
//       isSafe: false,
//       detectedAllergens: ['Gluten'],
//       confidence: 0.95,
//       date: DateTime.now().subtract(const Duration(days: 3)),
//     ),
//   ];
// }
