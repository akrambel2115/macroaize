import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macroaize/shared/models/subscription.dart';

void main() {
  group('Subscription Model Tests', () {
    group('fromFirestore factory', () {
      test('should parse valid Firestore data correctly', () {
        final firestoreData = {
          'isPremium': true,
          'planType': 'monthly',
          'startDate': Timestamp.fromDate(DateTime.utc(2024, 1, 1)),
          'endDate': Timestamp.fromDate(DateTime.utc(2024, 2, 1)),
          'provider': 'revenuecat',
          'status': 'active',
          'productId': 'premium_monthly',
        };

        final subscription = Subscription.fromFirestore(firestoreData);

        expect(subscription.isPremium, isTrue);
        expect(subscription.planType, equals('monthly'));
        expect(subscription.provider, equals('revenuecat'));
        expect(subscription.status, equals('active'));
        expect(subscription.productId, equals('premium_monthly'));
        expect(subscription.startDate, isNotNull);
        expect(subscription.endDate, isNotNull);
      });

      test('should handle null and missing fields gracefully', () {
        final minimalData = <String, dynamic>{};

        final subscription = Subscription.fromFirestore(minimalData);

        expect(subscription.isPremium, isFalse);
        expect(subscription.planType, isNull);
        expect(subscription.startDate, isNull);
        expect(subscription.endDate, isNull);
        expect(subscription.provider, isNull);
        expect(subscription.status, isNull);
        expect(subscription.productId, isNull);
      });

      test('should parse string dates correctly', () {
        final stringDateData = {
          'isPremium': true,
          'startDate': '2024-01-01T00:00:00.000Z',
          'endDate': '2024-02-01T00:00:00.000Z',
        };

        final subscription = Subscription.fromFirestore(stringDateData);

        expect(subscription.startDate, isNotNull);
        expect(subscription.endDate, isNotNull);
        expect(subscription.isPremium, isTrue);
      });

      test('should parse integer timestamps correctly', () {
        final timestampData = {
          'isPremium': true,
          'startDate': 1704067200, // seconds since epoch
          'endDate': 1706745600, // seconds since epoch
        };

        final subscription = Subscription.fromFirestore(timestampData);

        expect(subscription.startDate, isNotNull);
        expect(subscription.endDate, isNotNull);
        expect(subscription.isPremium, isTrue);
      });

      test('should handle millisecond timestamps correctly', () {
        final msTimestampData = {
          'isPremium': true,
          'startDate': 1704067200000, // milliseconds since epoch
          'endDate': 1706745600000, // milliseconds since epoch
        };

        final subscription = Subscription.fromFirestore(msTimestampData);

        expect(subscription.startDate, isNotNull);
        expect(subscription.endDate, isNotNull);
        expect(subscription.isPremium, isTrue);
      });

      test('should handle invalid date formats gracefully', () {
        final invalidDateData = {
          'isPremium': true,
          'startDate': 'invalid-date-string',
          'endDate': 'another-invalid-date',
        };

        final subscription = Subscription.fromFirestore(invalidDateData);

        expect(subscription.startDate, isNull);
        expect(subscription.endDate, isNull);
        expect(subscription.isPremium, isTrue);
      });
    });

    group('isActive getter', () {
      test(
        'should return true for active subscription with future end date',
        () {
          final futureDate = DateTime.now().toUtc().add(
            const Duration(days: 30),
          );
          final subscription = Subscription(
            isPremium: true,
            endDate: futureDate,
            status: 'active',
          );

          expect(subscription.isActive, isTrue);
        },
      );

      test('should return false for expired subscription', () {
        final pastDate = DateTime.now().toUtc().subtract(
          const Duration(days: 1),
        );
        final subscription = Subscription(
          isPremium: true,
          endDate: pastDate,
          status: 'expired',
        );

        expect(subscription.isActive, isFalse);
      });

      test('should return false when isPremium is false', () {
        final futureDate = DateTime.now().toUtc().add(const Duration(days: 30));
        final subscription = Subscription(
          isPremium: false,
          endDate: futureDate,
          status: 'active',
        );

        expect(subscription.isActive, isFalse);
      });

      test('should return false when endDate is null', () {
        final subscription = Subscription(
          isPremium: true,
          endDate: null,
          status: 'active',
        );

        expect(subscription.isActive, isFalse);
      });

      test('should handle edge case of endDate exactly now', () {
        final nowDate = DateTime.now().toUtc();
        final subscription = Subscription(
          isPremium: true,
          endDate: nowDate,
          status: 'active',
        );

        // Should be false since end date is not in the future
        expect(subscription.isActive, isFalse);
      });
    });

    group('Different providers', () {
      test('should support RevenueCat subscriptions', () {
        final subscription = Subscription(
          isPremium: true,
          planType: 'yearly',
          provider: 'revenuecat',
          status: 'active',
          productId: 'premium_yearly',
          endDate: DateTime.now().toUtc().add(const Duration(days: 365)),
        );

        expect(subscription.provider, equals('revenuecat'));
        expect(subscription.isActive, isTrue);
      });

      test('should support Chargily subscriptions', () {
        final subscription = Subscription(
          isPremium: true,
          planType: 'lifetime',
          provider: 'chargily',
          status: 'active',
          endDate: DateTime.now().toUtc().add(
            const Duration(days: 3650),
          ), // 10 years
        );

        expect(subscription.provider, equals('chargily'));
        expect(subscription.isActive, isTrue);
      });

      test('should handle unknown providers', () {
        final subscription = Subscription(
          isPremium: true,
          provider: 'unknown_provider',
          status: 'active',
          endDate: DateTime.now().toUtc().add(const Duration(days: 30)),
        );

        expect(subscription.provider, equals('unknown_provider'));
        expect(subscription.isActive, isTrue);
      });
    });

    group('Status variations', () {
      test('should handle different subscription statuses', () {
        final statuses = [
          'active',
          'canceled',
          'expired',
          'past_due',
          'paused',
        ];

        for (final status in statuses) {
          final subscription = Subscription(
            isPremium: status == 'active',
            status: status,
            endDate: DateTime.now().toUtc().add(const Duration(days: 30)),
          );

          expect(subscription.status, equals(status));
          expect(subscription.isActive, equals(status == 'active'));
        }
      });
    });

    group('Edge cases and error handling', () {
      test('should handle extremely large timestamps', () {
        final largeTimestampData = {
          'isPremium': true,
          'startDate': 9999999999999, // very large timestamp
          'endDate': 9999999999999,
        };

        final subscription = Subscription.fromFirestore(largeTimestampData);

        // Should not crash and should handle gracefully
        expect(subscription.isPremium, isTrue);
      });

      test('should handle negative timestamps', () {
        final negativeTimestampData = {
          'isPremium': true,
          'startDate': -1000000,
          'endDate': -500000,
        };

        final subscription = Subscription.fromFirestore(negativeTimestampData);

        expect(subscription.isPremium, isTrue);
        // Should not crash
      });

      test('should handle non-string, non-int, non-Timestamp date values', () {
        final weirdData = {
          'isPremium': true,
          'startDate': 12.34, // double
          'endDate': true, // boolean
        };

        final subscription = Subscription.fromFirestore(weirdData);

        expect(subscription.isPremium, isTrue);
        // Should handle gracefully without crashing
      });
    });
  });
}
