import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class MealSyncService {
  static final MealSyncService _instance = MealSyncService._internal();
  factory MealSyncService() => _instance;
  MealSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _logTag = 'MealSyncService';

  Future<void> syncMealLog({
    required String mealType,
    required int calories,
    required int protein,
    required int carbs,
    required int fats,
    required int dailyGoal,
  }) async {
    debugPrint('[$_logTag]  syncMealLog called: $mealType, $calories cal');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[$_logTag] ❌ No authenticated user, skipping sync');
        return;
      }

      debugPrint('[$_logTag]  User: ${user.uid}');

      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final userId = user.uid;

      final userRef = _firestore.collection('users').doc(userId);
      final mealTimeField = _getMealTimeField(mealType);

      debugPrint('[$_logTag]  Writing to users/$userId...');

      await userRef.set({
        'lastMealLog': FieldValue.serverTimestamp(),
        if (mealTimeField != null) mealTimeField: FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[$_logTag]  User document updated!');

      final historyRef = _firestore
          .collection('calorie_history')
          .doc('${userId}_$todayStr');

      debugPrint(
        '[$_logTag]  Writing to calorie_history/${userId}_$todayStr...',
      );

      await _firestore.runTransaction((transaction) async {
        final historyDoc = await transaction.get(historyRef);

        if (historyDoc.exists) {
          final data = historyDoc.data()!;
          final currentCalories = (data['totalCalories'] ?? 0) as int;
          final newTotal = currentCalories + calories;

          transaction.update(historyRef, {
            'totalCalories': newTotal,
            'totalProtein': FieldValue.increment(protein),
            'totalCarbs': FieldValue.increment(carbs),
            'totalFats': FieldValue.increment(fats),
            'mealCount': FieldValue.increment(1),
            'lastMealType': mealType,
            'lastMealAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(historyRef, {
            'userId': userId,
            'date': todayStr,
            'totalCalories': calories,
            'totalProtein': protein,
            'totalCarbs': carbs,
            'totalFats': fats,
            'targetCalories': dailyGoal,
            'mealCount': 1,
            'lastMealType': mealType,
            'lastMealAt': FieldValue.serverTimestamp(),
            'notified50': false,
            'notified100': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint('[$_logTag]  Calorie history updated!');
      debugPrint(
        '[$_logTag]  Meal sync complete: $mealType, $calories cal for user $userId',
      );
    } catch (e, stackTrace) {
      debugPrint('[$_logTag] ❌ Error syncing meal: $e');
      debugPrint('[$_logTag] Stack trace: $stackTrace');
      // background sync only
    }
  }

  Future<void> syncDailyGoal(int goal) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final historyRef = _firestore
          .collection('calorie_history')
          .doc('${user.uid}_$todayStr');

      await historyRef.set({
        'userId': user.uid,
        'date': todayStr,
        'targetCalories': goal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('[$_logTag] Synced daily goal: $goal');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error syncing goal: $e');
      }
    }
  }

  Future<void> ensureUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);

      await userRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'email': user.email,
        'displayName': user.displayName,
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('[$_logTag] User document ensured for ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error ensuring user document: $e');
      }
    }
  }

  String? _getMealTimeField(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'lastBreakfastLog';
      case 'lunch':
        return 'lastLunchLog';
      case 'dinner':
        return 'lastDinnerLog';
      case 'snack':
        return 'lastSnackLog';
      default:
        return null;
    }
  }
}
