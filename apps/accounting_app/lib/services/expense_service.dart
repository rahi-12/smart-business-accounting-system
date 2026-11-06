import '../models/expense.dart';
import 'api_service.dart';

class ExpenseService {
  ExpenseService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  static Map<String, String> buildListQuery({
    String? search,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.trim().isNotEmpty && category != 'All')
        'category': category.trim(),
      if (fromDate != null) 'startDate': _formatDate(fromDate),
      if (toDate != null) 'endDate': _formatDate(toDate),
    };

    final sortSpec = _resolveSort(sort, 'expense_date');
    query['sortBy'] = sortSpec['sortBy']!;
    query['order'] = sortSpec['order']!;
    return query;
  }

  static Map<String, String> _resolveSort(String sort, String defaultSortBy) {
    final normalized = sort.trim();
    switch (normalized) {
      case 'newest':
        return {'sortBy': defaultSortBy, 'order': 'desc'};
      case 'oldest':
        return {'sortBy': defaultSortBy, 'order': 'asc'};
      case 'amount_desc':
        return {'sortBy': 'amount', 'order': 'desc'};
      case 'amount_asc':
        return {'sortBy': 'amount', 'order': 'asc'};
      default:
        return {'sortBy': defaultSortBy, 'order': 'desc'};
    }
  }

  Future<ExpensePage> fetchExpenses({
    String? search,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) async {
    final query = buildListQuery(
      search: search,
      category: category,
      fromDate: fromDate,
      toDate: toDate,
      sort: sort,
      page: page,
      limit: limit,
    );

    final response = await _apiService.getExpenses(queryParameters: query);
    return response;
  }

  Future<ExpenseRecord> createExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) {
    return _apiService.createExpense(
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
    return _apiService.updateExpense(
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
    return _apiService.deleteExpense(id);
  }

  static String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
