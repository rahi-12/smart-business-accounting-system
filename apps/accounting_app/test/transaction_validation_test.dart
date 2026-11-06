import 'package:accounting_app/utils/transaction_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionValidation.title', () {
    test('accepts minimum 1-character title and rejects empty values', () {
      expect(TransactionValidation.validateTitle('A'), isNull);
      expect(TransactionValidation.validateTitle('   '), 'Title is required.');
    });

    test('accepts 150 characters and rejects 151 characters', () {
      final validTitle = 'A' * 150;
      final invalidTitle = 'A' * 151;

      expect(TransactionValidation.validateTitle(validTitle), isNull);
      expect(
        TransactionValidation.validateTitle(invalidTitle),
        'Title must be 150 characters or fewer.',
      );
    });
  });

  group('TransactionValidation.category', () {
    test('accepts minimum 1-character category and rejects empty values', () {
      expect(TransactionValidation.validateCategory('Sales'), isNull);
      expect(
        TransactionValidation.validateCategory('   '),
        'Category is required.',
      );
    });

    test('accepts 100 characters and rejects 101 characters', () {
      final validCategory = 'A' * 100;
      final invalidCategory = 'A' * 101;

      expect(TransactionValidation.validateCategory(validCategory), isNull);
      expect(
        TransactionValidation.validateCategory(invalidCategory),
        'Category must be 100 characters or fewer.',
      );
    });
  });

  group('TransactionValidation.paymentMethod', () {
    test('accepts a populated payment method and rejects blank values', () {
      expect(TransactionValidation.validatePaymentMethod('Cash'), isNull);
      expect(
        TransactionValidation.validatePaymentMethod('   '),
        'Payment method is required.',
      );
    });

    test('accepts 50 characters and rejects 51 characters', () {
      final validPaymentMethod = 'A' * 50;
      final invalidPaymentMethod = 'A' * 51;

      expect(
        TransactionValidation.validatePaymentMethod(validPaymentMethod),
        isNull,
      );
      expect(
        TransactionValidation.validatePaymentMethod(invalidPaymentMethod),
        'Payment method must be 50 characters or fewer.',
      );
    });
  });

  group('TransactionValidation.amount', () {
    test('accepts valid boundaries and rejects invalid boundaries', () {
      expect(TransactionValidation.validateAmount('0.01'), isNull);
      expect(TransactionValidation.validateAmount('9999999999.99'), isNull);
      expect(
        TransactionValidation.validateAmount('0'),
        'Amount must be greater than 0 and fit NUMERIC(12,2).',
      );
      expect(
        TransactionValidation.validateAmount('-1'),
        'Amount must be a positive number with at most two decimal places.',
      );
      expect(
        TransactionValidation.validateAmount('10000000000'),
        'Amount must be greater than 0 and fit NUMERIC(12,2).',
      );
      expect(
        TransactionValidation.validateAmount('123.456'),
        'Amount must be a positive number with at most two decimal places.',
      );
      expect(
        TransactionValidation.validateAmount('1.234'),
        'Amount must be a positive number with at most two decimal places.',
      );
      expect(TransactionValidation.validateAmount(''), 'Amount is required.');
    });
  });

  group('TransactionValidation.description', () {
    test('accepts blank or null and rejects values above 5000 characters', () {
      expect(TransactionValidation.validateDescription(''), isNull);
      expect(TransactionValidation.validateDescription(null), isNull);
      expect(TransactionValidation.validateDescription('A' * 5000), isNull);
      expect(
        TransactionValidation.validateDescription('A' * 5001),
        'Description must be 5000 characters or fewer.',
      );
      expect(
        TransactionValidation.descriptionRemainingText('A' * 10),
        '4990 characters left',
      );
    });
  });

  group('TransactionValidation.dateString', () {
    test(
      'accepts valid dates and rejects invalid dates including year 0000',
      () {
        expect(
          TransactionValidation.validateDateString(
            '2024-02-29',
            fieldName: 'Income date',
          ),
          isNull,
        );
        expect(
          TransactionValidation.validateDateString(
            '2023-02-29',
            fieldName: 'Expense date',
          ),
          'Expense date must be a valid date in YYYY-MM-DD format.',
        );
        expect(
          TransactionValidation.validateDateString(
            '0000-01-01',
            fieldName: 'Income date',
          ),
          'Income date must be a valid date in YYYY-MM-DD format.',
        );
        expect(
          TransactionValidation.validateDateString(
            '2024-02-30',
            fieldName: 'Income date',
          ),
          'Income date must be a valid date in YYYY-MM-DD format.',
        );
      },
    );
  });
}
