import 'package:accounting_app/utils/customer_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomerValidation', () {
    test('name accepts minimum and rejects overflow', () {
      expect(CustomerValidation.validateName('A'), isNull);
      expect(CustomerValidation.validateName('A' * 150), isNull);
      expect(CustomerValidation.validateName('A' * 151),
          'Name must be 150 characters or fewer.');
      expect(CustomerValidation.validateName('   '), 'Name is required.');
    });

    test('phone accepts blank and max length rules', () {
      expect(CustomerValidation.validatePhone(null), isNull);
      expect(CustomerValidation.validatePhone(''), isNull);
      expect(CustomerValidation.validatePhone('1' * 30), isNull);
      expect(CustomerValidation.validatePhone('1' * 31),
          'Phone must be 30 characters or fewer.');
    });

    test('email accepts valid pattern and rejects invalid or too-long values', () {
      expect(CustomerValidation.validateEmail(null), isNull);
      expect(CustomerValidation.validateEmail('user@example.com'), isNull);
      expect(CustomerValidation.validateEmail('user@localhost'),
          'Email must be a valid email address.');
      final maxLengthValidEmail = '${'a' * 138}@example.com';
      expect(CustomerValidation.validateEmail(maxLengthValidEmail), isNull);
      expect(CustomerValidation.validateEmail('${maxLengthValidEmail}a'),
          'Email must be 150 characters or fewer.');
    });

    test('address and notes obey API limits', () {
      expect(CustomerValidation.validateAddress(null), isNull);
      expect(CustomerValidation.validateAddress('A' * 500), isNull);
      expect(CustomerValidation.validateAddress('A' * 501),
          'Address must be 500 characters or fewer.');
      expect(CustomerValidation.validateNotes(null), isNull);
      expect(CustomerValidation.validateNotes('A' * 5000), isNull);
      expect(CustomerValidation.validateNotes('A' * 5001),
          'Notes must be 5000 characters or fewer.');
    });

    test('notes remaining text shows remaining count', () {
      expect(CustomerValidation.notesRemainingText('A' * 10), '4990 characters left');
    });
  });
}
