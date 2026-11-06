import '../models/income.dart';
import '../services/income_service.dart';

class IncomeRepository {
  IncomeRepository({IncomeService? service})
    : _service = service ?? IncomeService();

  final IncomeService _service;

  Future<IncomePage> fetchIncomes({
    String? search,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) {
    return _service.fetchIncomes(
      search: search,
      category: category,
      fromDate: fromDate,
      toDate: toDate,
      sort: sort,
      page: page,
      limit: limit,
    );
  }

  Future<IncomeRecord> createIncome({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) {
    return _service.createIncome(
      title: title,
      category: category,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      description: description,
    );
  }

  Future<IncomeRecord> updateIncome({
    required String id,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) {
    return _service.updateIncome(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      description: description,
    );
  }

  Future<void> deleteIncome(String id) {
    return _service.deleteIncome(id);
  }
}
