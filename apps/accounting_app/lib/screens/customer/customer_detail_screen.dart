import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../view_models/customer_view_model.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.viewModel,
  });

  final CustomerRecord customer;
  final CustomerViewModel viewModel;

  Future<void> _deleteCustomer(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1F18),
        title: const Text('Deactivate customer?'),
        content: const Text(
          'This customer will be deactivated, and the invoice history will be kept.',
          style: TextStyle(color: Color(0xFFB0C7B9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A80),
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final success = await viewModel.deleteCustomer(customer.id);
    if (!context.mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.errorMessage ?? 'Unable to delete customer.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = (customer.email ?? '').trim().isNotEmpty;
    final hasPhone = (customer.phone ?? '').trim().isNotEmpty;
    final hasAddress = (customer.address ?? '').trim().isNotEmpty;
    final hasNotes = (customer.notes ?? '').trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF07130E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F18),
        foregroundColor: Colors.white,
        title: const Text('Customer details'),
        actions: [
          IconButton(
            tooltip: 'Edit customer',
            onPressed: () async {
              final didUpdate = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CustomerFormScreen(
                    viewModel: viewModel,
                    customer: customer,
                  ),
                ),
              );
              if (didUpdate == true) {
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            },
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Deactivate customer',
            onPressed: () => _deleteCustomer(context),
            icon: const Icon(Icons.delete_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(customer.isActive ? 'Active' : 'Inactive'),
                backgroundColor: customer.isActive
                    ? const Color(0xFF1E7A5B).withAlpha(80)
                    : const Color(0xFFDBA13C).withAlpha(80),
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Contact',
                rows: [
                  if (hasPhone) _InfoRow(label: 'Phone', value: customer.phone!),
                  if (hasEmail) _InfoRow(label: 'Email', value: customer.email!),
                  if (!hasPhone && !hasEmail)
                    _InfoRow(label: 'Contact', value: 'No contact details saved.'),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Address',
                rows: [
                  if (hasAddress)
                    _InfoRow(label: 'Address', value: customer.address!)
                  else
                    _InfoRow(label: 'Address', value: 'No address on file.'),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Notes',
                rows: [
                  if (hasNotes)
                    _InfoRow(label: 'Notes', value: customer.notes!)
                  else
                    _InfoRow(label: 'Notes', value: 'No notes saved.'),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Audit',
                rows: [
                  _InfoRow(
                    label: 'Created',
                    value: customer.createdAt.toLocal().toString(),
                  ),
                  _InfoRow(
                    label: 'Updated',
                    value: customer.updatedAt.toLocal().toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0E1F18),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: const TextStyle(
                        color: Color(0xFFB0C7B9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
}
