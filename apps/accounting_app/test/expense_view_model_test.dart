import 'package:accounting_app/models/expense.dart';
import 'package:accounting_app/repositories/expense_repository.dart';
import 'package:accounting_app/view_models/expense_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExpenseRepository extends ExpenseRepository {
  _FakeExpenseRepository({this.pageResult, this.errorMessage});

  final ExpensePage? pageResult;
  final String? errorMessage;

  @override
  Future<ExpensePage> fetchExpenses({
    String? search,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) async {
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }

    return pageResult ??
        ExpensePage(
          items: const <ExpenseRecord>[],
          hasMore: false,
          total: 0,
          page: 1,
          limit: 20,
        );
  }

  @override
  Future<ExpenseRecord> createExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }

    return ExpenseRecord(
      id: 'created-1',
      title: title,
      amount: amount,
      category: category,
      expenseDate: date,
      description: description,
      paymentMethod: paymentMethod,
    );
  }
}

void main() {
  test('expense view model loads expenses and clears errors', () async {
    final repository = _FakeExpenseRepository(
      pageResult: ExpensePage(
        items: [
          ExpenseRecord(
            id: '1',
            title: 'Internet',
            amount: 4200,
            category: 'Utilities',
            expenseDate: DateTime(2026, 3, 5),
          ),
        ],
        hasMore: false,
        total: 1,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
    );

    final viewModel = ExpenseViewModel(repository: repository);
    await viewModel.loadInitial();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.items.length, 1);
    expect(viewModel.errorMessage, isNull);
  });

  test('expense view model reports request failures', () async {
    final viewModel = ExpenseViewModel(
      repository: _FakeExpenseRepository(errorMessage: 'Server error'),
    );

    await viewModel.loadInitial();

    expect(viewModel.items, isEmpty);
    expect(viewModel.errorMessage, contains('Server error'));
  });

  test('saveExpense creates record and refreshes the list', () async {
    final repository = _FakeExpenseRepository(
      pageResult: ExpensePage(
        items: const <ExpenseRecord>[],
        hasMore: false,
        total: 0,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
    );

    final viewModel = ExpenseViewModel(repository: repository);
    final saved = await viewModel.saveExpense(
      title: 'Staff lunch',
      category: 'Operations',
      amount: 1250,
      date: DateTime(2026, 4, 12),
      paymentMethod: 'Cash',
      description: 'Team meal',
    );

    expect(saved, isTrue);
    expect(viewModel.errorMessage, isNull);
  });
}
