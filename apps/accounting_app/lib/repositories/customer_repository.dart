import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerRepository {
  CustomerRepository({CustomerService? service})
    : _service = service ?? CustomerService();

  final CustomerService _service;

  Future<CustomerPage> fetchCustomers({
    String? search,
    String sortBy = 'name',
    String order = 'asc',
    bool includeInactive = false,
    int page = 1,
    int limit = 20,
  }) {
    return _service.fetchCustomers(
      search: search,
      sortBy: sortBy,
      order: order,
      includeInactive: includeInactive,
      page: page,
      limit: limit,
    );
  }

  Future<CustomerRecord> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return _service.createCustomer(
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
    return _service.updateCustomer(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }

  Future<CustomerRecord> getCustomer(String id) {
    return _service.getCustomer(id);
  }

  Future<void> deleteCustomer(String id) {
    return _service.deleteCustomer(id);
  }
}
