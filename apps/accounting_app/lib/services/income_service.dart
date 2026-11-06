import '../models/income.dart';
import 'api_service.dart';

class IncomeService {
  IncomeService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

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

    final sortSpec = _resolveSort(sort, 'income_date');
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

  Future<IncomePage> fetchIncomes({
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

    final response = await _apiService.getIncomes(queryParameters: query);
    return response;
  }

  Future<IncomeRecord> createIncome({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) {
    return _apiService.createIncome(
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
    return _apiService.updateIncome(
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
    return _apiService.deleteIncome(id);
  }

  static String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
