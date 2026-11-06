import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../view_models/customer_view_model.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _viewModel = CustomerViewModel();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _sortBy = 'name';
  String _order = 'asc';
  bool _includeInactive = false;

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
    if (_scrollController.position.extentAfter < 250 &&
        !_viewModel.isLoadingMore &&
        _viewModel.hasMore) {
      _viewModel.loadMore();
    }
  }

  Future<void> _applyFilters() async {
    await _viewModel.loadInitial(
      search: _searchController.text.trim(),
      sortBy: _sortBy,
      order: _order,
      includeInactive: _includeInactive,
    );
  }

  Future<void> _openForm({CustomerRecord? customer}) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(viewModel: _viewModel, customer: customer),
      ),
    );

    if (didChange == true && mounted) {
      await _viewModel.refresh();
    }
  }

  Future<void> _openDetails(CustomerRecord customer) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer, viewModel: _viewModel),
      ),
    );

    if (didChange == true && mounted) {
      await _viewModel.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final items = _viewModel.items;

        return Scaffold(
          backgroundColor: const Color(0xFF07130E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E1F18),
            foregroundColor: Colors.white,
            title: const Text('Customers'),
            actions: [
              IconButton(
                tooltip: 'Add customer',
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
                            hintText: 'Search customers',
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
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: _sortBy,
                                dropdownColor: const Color(0xFF0E1F18),
                                decoration: const InputDecoration(
                                  labelText: 'Sort by',
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'name', child: Text('Name')),
                                  DropdownMenuItem(value: 'email', child: Text('Email')),
                                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                                  DropdownMenuItem(value: 'created_at', child: Text('Created')),
                                  DropdownMenuItem(value: 'updated_at', child: Text('Updated')),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _sortBy = value);
                                    await _applyFilters();
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<String>(
                                initialValue: _order,
                                dropdownColor: const Color(0xFF0E1F18),
                                decoration: const InputDecoration(
                                  labelText: 'Order',
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _order = value);
                                    await _applyFilters();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          value: _includeInactive,
                          onChanged: (value) async {
                            setState(() => _includeInactive = value);
                            await _applyFilters();
                          },
                          title: const Text(
                            'Include inactive',
                            style: TextStyle(color: Colors.white),
                          ),
                          activeThumbColor: const Color(0xFF1E7A5B),
                          activeTrackColor: const Color(0xFF1E7A5B).withAlpha(180),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_viewModel.isLoading && items.isEmpty)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E7A5B)),
                    ),
                  )
                else if (_viewModel.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No customers found.',
                        style: TextStyle(color: Color(0xFFB0C7B9)),
                      ),
                    ),
                  )
                else if (_viewModel.errorMessage != null && items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _viewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else
                  ...items.map(
                    (customer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: const Color(0xFF0E1F18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          onTap: () => _openDetails(customer),
                          title: Text(
                            customer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((customer.email ?? '').trim().isNotEmpty)
                                Text(customer.email!, style: const TextStyle(color: Color(0xFFB0C7B9))),
                              if ((customer.phone ?? '').trim().isNotEmpty)
                                Text(customer.phone!, style: const TextStyle(color: Color(0xFFB0C7B9))),
                              Text(
                                customer.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: customer.isActive
                                      ? const Color(0xFF58B98B)
                                      : const Color(0xFFFFD166),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                if (_viewModel.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E7A5B)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
