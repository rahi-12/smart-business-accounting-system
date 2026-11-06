import 'package:flutter/material.dart';

import '../../models/income.dart';
import '../../view_models/income_view_model.dart';
import 'income_form_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final IncomeViewModel _viewModel = IncomeViewModel();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _category = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _viewModel.loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 240 &&
        !_viewModel.isLoadingMore &&
        _viewModel.hasMore) {
      _viewModel.loadMore();
    }
  }

  Future<void> _applyFilters() async {
    await _viewModel.loadInitial(
      search: _searchController.text,
      category: _category,
      fromDate: _fromDate,
      toDate: _toDate,
      sort: _sort,
    );
  }

  Future<void> _openForm({IncomeRecord? income}) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IncomeFormScreen(viewModel: _viewModel, income: income),
      ),
    );

    if (didChange == true && mounted) {
      await _viewModel.refresh();
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();
    final initialDate = (isFrom ? _fromDate : _toDate) ?? lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
    await _applyFilters();
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    setState(() {
      _category = 'All';
      _fromDate = null;
      _toDate = null;
      _sort = 'newest';
    });
    await _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final viewModel = _viewModel;

        return Scaffold(
          backgroundColor: const Color(0xFF07130E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E1F18),
            foregroundColor: Colors.white,
            title: const Text('Income'),
            actions: [
              IconButton(
                tooltip: 'Add income',
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF1E7A5B),
            onRefresh: () => _viewModel.refresh(),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFF0E1F18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search income',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF122A22),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _applyFilters(),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 160,
                              child: DropdownButtonFormField<String>(
                                initialValue: _category,
                                dropdownColor: const Color(0xFF0E1F18),
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All categories'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Sales',
                                    child: Text('Sales'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Services',
                                    child: Text('Services'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Rent',
                                    child: Text('Rent'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Other',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _category = value);
                                    await _applyFilters();
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<String>(
                                initialValue: _sort,
                                dropdownColor: const Color(0xFF0E1F18),
                                decoration: const InputDecoration(
                                  labelText: 'Sort by',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'newest',
                                    child: Text('Newest'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'oldest',
                                    child: Text('Oldest'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'amount_desc',
                                    child: Text('Largest'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'amount_asc',
                                    child: Text('Smallest'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _sort = value);
                                    await _applyFilters();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _pickDate(isFrom: true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'From date',
                                  ),
                                  child: Text(
                                    _fromDate == null
                                        ? 'Any'
                                        : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _pickDate(isFrom: false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'To date',
                                  ),
                                  child: Text(
                                    _toDate == null
                                        ? 'Any'
                                        : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all_rounded),
                              label: const Text('Clear filters'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _applyFilters,
                              icon: const Icon(Icons.filter_alt_rounded),
                              label: const Text('Apply'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (viewModel.isLoading && viewModel.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1E7A5B),
                        ),
                      ),
                    ),
                  )
                else if (viewModel.errorMessage != null &&
                    viewModel.items.isEmpty)
                  _EmptyState(
                    title: 'Income unavailable',
                    subtitle: viewModel.errorMessage!,
                    onRetry: () => _viewModel.refresh(),
                  )
                else if (viewModel.isEmpty)
                  const _EmptyState(
                    title: 'No income records',
                    subtitle: 'Add your first income entry to get started.',
                  )
                else
                  ...viewModel.items.map((income) {
                    final isPositive = income.amount >= 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: const Color(0xFF0E1F18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _openForm(income: income),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E7A5B).withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Color(0xFF58B98B),
                            ),
                          ),
                          title: Text(
                            income.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${income.category} • ${_formatDate(income.incomeDate)}',
                                style: const TextStyle(
                                  color: Color(0xFFB0C7B9),
                                ),
                              ),
                              Text(
                                'Payment: ${income.paymentMethod ?? 'Not set'}',
                                style: const TextStyle(
                                  color: Color(0xFFB0C7B9),
                                  fontSize: 12,
                                ),
                              ),
                              if ((income.description ?? '').isNotEmpty)
                                Text(
                                  income.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFB0C7B9),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(income.amount),
                                style: TextStyle(
                                  color: isPositive
                                      ? const Color(0xFF58B98B)
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Income',
                                style: TextStyle(
                                  color: Color(0xFFB0C7B9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (viewModel.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1E7A5B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF1E7A5B),
            onPressed: () => _openForm(),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  static String _formatCurrency(double value) {
    final rounded = value.round();
    final formatted = rounded.toString().replaceAllMapped(
      RegExp(r'\d(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(0)},',
    );
    return 'KES $formatted';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0E1F18),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB0C7B9)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7A5B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
