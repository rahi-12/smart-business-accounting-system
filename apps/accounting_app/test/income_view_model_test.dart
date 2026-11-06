import 'package:accounting_app/models/income.dart';
import 'package:accounting_app/repositories/income_repository.dart';
import 'package:accounting_app/view_models/income_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIncomeRepository extends IncomeRepository {
  _FakeIncomeRepository({this.pageResult, this.errorMessage});

  final IncomePage? pageResult;
  final String? errorMessage;

  @override
  Future<IncomePage> fetchIncomes({
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
        IncomePage(
          items: const <IncomeRecord>[],
          hasMore: false,
          total: 0,
          page: 1,
          limit: 20,
        );
  }

  @override
  Future<IncomeRecord> createIncome({
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

    return IncomeRecord(
      id: 'created-1',
      title: title,
      amount: amount,
      category: category,
      incomeDate: date,
      description: description,
      paymentMethod: paymentMethod,
    );
  }
}

void main() {
  test('view model loads a list of incomes and clears errors', () async {
    final repository = _FakeIncomeRepository(
      pageResult: IncomePage(
        items: [
          IncomeRecord(
            id: '1',
            title: 'Consulting',
            amount: 35000,
            category: 'Services',
            incomeDate: DateTime(2026, 1, 12),
          ),
        ],
        hasMore: false,
        total: 1,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
    );

    final viewModel = IncomeViewModel(repository: repository);
    await viewModel.loadInitial();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.items.length, 1);
    expect(viewModel.errorMessage, isNull);
  });

  test('view model exposes loading errors for failed requests', () async {
    final viewModel = IncomeViewModel(
      repository: _FakeIncomeRepository(errorMessage: 'Server error'),
    );

    await viewModel.loadInitial();

    expect(viewModel.items, isEmpty);
    expect(viewModel.errorMessage, contains('Server error'));
  });

  test('saveIncome creates a record and refreshes the list', () async {
    final repository = _FakeIncomeRepository(
      pageResult: IncomePage(
        items: const <IncomeRecord>[],
        hasMore: false,
        total: 0,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
    );
    final viewModel = IncomeViewModel(repository: repository);

    final saved = await viewModel.saveIncome(
      title: 'New invoice',
      category: 'Sales',
      amount: 15000,
      date: DateTime(2026, 2, 10),
      paymentMethod: 'Bank Transfer',
      description: 'Website package',
    );

    expect(saved, isTrue);
    expect(viewModel.errorMessage, isNull);
  });
}
