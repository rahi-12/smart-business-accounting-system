import '../models/customer.dart';
import 'api_service.dart';

class CustomerService {
  CustomerService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  static Map<String, String> buildListQuery({
    String? search,
    String sortBy = 'name',
    String order = 'asc',
    bool includeInactive = false,
    int page = 1,
    int limit = 20,
  }) {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (sortBy.isNotEmpty) 'sortBy': sortBy,
      if (order.isNotEmpty) 'order': order,
      'includeInactive': includeInactive.toString(),
    };
    return query;
  }

  Future<CustomerPage> fetchCustomers({
    String? search,
    String sortBy = 'name',
    String order = 'asc',
    bool includeInactive = false,
    int page = 1,
    int limit = 20,
  }) async {
    final query = buildListQuery(
      search: search,
      sortBy: sortBy,
      order: order,
      includeInactive: includeInactive,
      page: page,
      limit: limit,
    );
    return _apiService.getCustomers(queryParameters: query);
  }

  Future<CustomerRecord> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return _apiService.createCustomer(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }

  Future<CustomerRecord> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return _apiService.updateCustomer(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }

  Future<CustomerRecord> getCustomer(String id) {
    return _apiService.getCustomer(id);
  }

  Future<void> deleteCustomer(String id) {
    return _apiService.deleteCustomer(id);
  }
}
