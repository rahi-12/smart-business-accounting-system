import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseRepository {
  ExpenseRepository({ExpenseService? service}) : _service = service ?? ExpenseService();

  final ExpenseService _service;

  Future<ExpensePage> fetchExpenses({
    String? search,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) {
    return _service.fetchExpenses(
      search: search,
      category: category,
      fromDate: fromDate,
      toDate: toDate,
      sort: sort,
      page: page,
      limit: limit,
    );
  }

  Future<ExpenseRecord> createExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) {
    return _service.createExpense(
      title: title,
      category: category,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      description: description,
    );
  }

  Future<ExpenseRecord> updateExpense({
    required String id,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) {
    return _service.updateExpense(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      description: description,
    );
  }

  Future<void> deleteExpense(String id) {
    return _service.deleteExpense(id);
  }
}
