import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  ExpenseViewModel({ExpenseRepository? repository})
      : _repository = repository ?? ExpenseRepository();

  final ExpenseRepository _repository;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  List<ExpenseRecord> _items = const <ExpenseRecord>[];

  int _currentPage = 1;
  String _search = '';
  String _category = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sort = 'newest';

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<ExpenseRecord> get items => _items;
  bool get isEmpty => !_isLoading && _errorMessage == null && _items.isEmpty;

  Future<void> loadInitial({
    String? search,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'newest',
  }) async {
    _search = search ?? '';
    _category = category ?? 'All';
    _fromDate = fromDate;
    _toDate = toDate;
    _sort = sort;
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
      final page = await _repository.fetchExpenses(
        search: _search,
        category: _category,
        fromDate: _fromDate,
        toDate: _toDate,
        sort: _sort,
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
      category: _category,
      fromDate: _fromDate,
      toDate: _toDate,
      sort: _sort,
    );
  }

  Future<bool> saveExpense({
    String? id,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      if (id == null || id.isEmpty) {
        await _repository.createExpense(
          title: title,
          category: category,
          amount: amount,
          date: date,
          paymentMethod: paymentMethod,
          description: description,
        );
      } else {
        await _repository.updateExpense(
          id: id,
          title: title,
          category: category,
          amount: amount,
          date: date,
          paymentMethod: paymentMethod,
          description: description,
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

  Future<bool> deleteExpense(String id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteExpense(id);
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
      final page = await _repository.fetchExpenses(
        search: _search,
        category: _category,
        fromDate: _fromDate,
        toDate: _toDate,
        sort: _sort,
        page: _currentPage,
      );
      _items = resetItems ? page.items : [..._items, ...page.items];
      _currentPage = page.page;
      _hasMore = page.hasMore;
      _errorMessage = null;
    } catch (error) {
      if (resetItems) {
        _items = const <ExpenseRecord>[];
      }
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
