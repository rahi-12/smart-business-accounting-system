import 'package:accounting_app/models/expense.dart';
import 'package:accounting_app/models/income.dart';
import 'package:accounting_app/services/expense_service.dart';
import 'package:accounting_app/services/income_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contract query builders', () {
    test('income service uses backend contract query keys and date format', () {
      final query = IncomeService.buildListQuery(
        search: '  client ',
        category: 'Sales',
        fromDate: DateTime(2026, 1, 5),
        toDate: DateTime(2026, 1, 15),
        sort: 'newest',
        page: 2,
        limit: 10,
      );

      expect(
        query.keys,
        containsAll(<String>[
          'page',
          'limit',
          'search',
          'category',
          'startDate',
          'endDate',
          'sortBy',
          'order',
        ]),
      );
      expect(query['search'], 'client');
      expect(query['category'], 'Sales');
      expect(query['page'], '2');
      expect(query['limit'], '10');
      expect(query['startDate'], '2026-01-05');
      expect(query['endDate'], '2026-01-15');
      expect(query['sortBy'], 'income_date');
      expect(query['order'], 'desc');
    });

    test('expense service maps dropdown values to backend sortBy and order', () {
      final newest = ExpenseService.buildListQuery(sort: 'newest');
      final oldest = ExpenseService.buildListQuery(sort: 'oldest');
      final largest = ExpenseService.buildListQuery(sort: 'amount_desc');
      final smallest = ExpenseService.buildListQuery(sort: 'amount_asc');

      expect(newest['sortBy'], 'expense_date');
      expect(newest['order'], 'desc');
      expect(oldest['sortBy'], 'expense_date');
      expect(oldest['order'], 'asc');
      expect(largest['sortBy'], 'amount');
      expect(largest['order'], 'desc');
      expect(smallest['sortBy'], 'amount');
      expect(smallest['order'], 'asc');
    });
  });

  group('pagination parsing', () {
    test('income page parser reads totalPages and disables hasMore on last page', () {
      final json = {
        'items': [
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'title': 'Website retainer',
            'amount': 15000,
            'category': 'Services',
            'payment_method': 'Bank Transfer',
            'income_date': '2026-01-05',
            'description': 'Monthly design retainer',
          },
          {
            'id': '22222222-2222-4222-8222-222222222222',
            'title': 'App sales',
            'amount': 22000,
            'category': 'Sales',
            'payment_method': 'Card',
            'income_date': '2026-01-10',
            'description': null,
          },
        ],
        'pagination': {
          'page': 2,
          'limit': 10,
          'total': 15,
          'totalPages': 2,
        },
      };

      final page = IncomePage.fromJson(json);

      expect(page.page, 2);
      expect(page.limit, 10);
      expect(page.total, 15);
      expect(page.totalPages, 2);
      expect(page.hasMore, isFalse);
      expect(page.items.length, 2);
    });

    test('expense page parser keeps hasMore true until the final page', () {
      final json = {
        'items': [
          {
            'id': '33333333-3333-4333-8333-333333333333',
            'title': 'Office rent',
            'amount': 12000,
            'category': 'Operations',
            'payment_method': 'Bank Transfer',
            'expense_date': '2026-01-02',
            'description': 'Warehouse rent',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 10,
          'total': 25,
          'totalPages': 3,
        },
      };

      final page = ExpensePage.fromJson(json);

      expect(page.page, 1);
      expect(page.limit, 10);
      expect(page.total, 25);
      expect(page.totalPages, 3);
      expect(page.hasMore, isTrue);
    });
  });
}
