import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerViewModel extends ChangeNotifier {
  CustomerViewModel({CustomerRepository? repository})
    : _repository = repository ?? CustomerRepository();

  final CustomerRepository _repository;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  List<CustomerRecord> _items = const <CustomerRecord>[];

  int _currentPage = 1;
  String _search = '';
  String _sortBy = 'name';
  String _order = 'asc';
  bool _includeInactive = false;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<CustomerRecord> get items => _items;
  bool get isEmpty => !_isLoading && _errorMessage == null && _items.isEmpty;

  Future<void> loadInitial({
    String? search,
    String sortBy = 'name',
    String order = 'asc',
    bool includeInactive = false,
  }) async {
    _search = search ?? '';
    _sortBy = sortBy;
    _order = order;
    _includeInactive = includeInactive;
    _currentPage = 1;
    await _loadPage(resetItems: true);
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchCustomers(
        search: _search,
        sortBy: _sortBy,
        order: _order,
        includeInactive: _includeInactive,
        page: _currentPage + 1,
      );
      final existingIds = _items.map((item) => item.id).toSet();
      final newItems = page.items.where((item) => !existingIds.contains(item.id)).toList();
      _items.addAll(newItems);
      _currentPage = page.page;
      _hasMore = page.hasMore;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() {
    return loadInitial(
      search: _search,
      sortBy: _sortBy,
      order: _order,
      includeInactive: _includeInactive,
    );
  }

  Future<CustomerRecord> fetchCustomer(String id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository.getCustomer(id);
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> saveCustomer({
    String? id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      if (id == null || id.isEmpty) {
        await _repository.createCustomer(
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        );
      } else {
        await _repository.updateCustomer(
          id: id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        );
      }
      await refresh();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCustomer(id);
      await refresh();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadPage({required bool resetItems}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchCustomers(
        search: _search,
        sortBy: _sortBy,
        order: _order,
        includeInactive: _includeInactive,
        page: _currentPage,
      );
      _items = resetItems ? page.items : [..._items, ...page.items];
      _currentPage = page.page;
      _hasMore = page.hasMore;
      _errorMessage = null;
    } catch (error) {
      if (resetItems) {
        _items = const <CustomerRecord>[];
      }
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
