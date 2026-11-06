import 'package:flutter/foundation.dart';

import '../models/income.dart';
import '../repositories/income_repository.dart';

class IncomeViewModel extends ChangeNotifier {
  IncomeViewModel({IncomeRepository? repository})
    : _repository = repository ?? IncomeRepository();

  final IncomeRepository _repository;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  List<IncomeRecord> _items = const <IncomeRecord>[];

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
  List<IncomeRecord> get items => _items;
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
      final page = await _repository.fetchIncomes(
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

  Future<bool> saveIncome({
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
        await _repository.createIncome(
          title: title,
          category: category,
          amount: amount,
          date: date,
          paymentMethod: paymentMethod,
          description: description,
        );
      } else {
        await _repository.updateIncome(
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

  Future<bool> deleteIncome(String id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteIncome(id);
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
      final page = await _repository.fetchIncomes(
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
        _items = const <IncomeRecord>[];
      }
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
