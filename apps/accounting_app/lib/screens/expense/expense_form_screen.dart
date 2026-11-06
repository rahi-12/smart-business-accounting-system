import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/expense.dart';
import '../../utils/transaction_validation.dart';
import '../../view_models/expense_view_model.dart';
import '../../widgets/payment_method_field.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.viewModel, this.expense});

  final ExpenseViewModel viewModel;
  final ExpenseRecord? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _paymentMethod;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _titleController.text = expense.title;
      _categoryController.text = expense.category;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedDate = expense.expenseDate;
      _descriptionController.text = expense.description ?? '';
      _paymentMethod = expense.paymentMethod;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final dateError = TransactionValidation.validateDateString(
      _selectedDate.toIso8601String().substring(0, 10),
      fieldName: 'Expense date',
    );
    if (dateError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(dateError)));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.viewModel.saveExpense(
      id: widget.expense?.id,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      date: _selectedDate,
      paymentMethod: _paymentMethod ?? '',
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = false);
    final message = widget.viewModel.errorMessage ?? 'Unable to save expense.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1F18),
        title: const Text('Delete expense?'),
        content: const Text(
          'This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || widget.expense == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.viewModel.deleteExpense(widget.expense!.id);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = false);
    final message =
        widget.viewModel.errorMessage ?? 'Unable to delete expense.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      backgroundColor: const Color(0xFF07130E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F18),
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Edit expense' : 'Add expense'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Update expense details'
                      : 'Enter a new expense record',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  maxLength: TransactionValidation.maxTitleLength,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Office supplies',
                  ),
                  validator: TransactionValidation.validateTitle,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  maxLength: TransactionValidation.maxCategoryLength,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Operations, Payroll, Utilities',
                  ),
                  validator: TransactionValidation.validateCategory,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}$'),
                    ),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '25000',
                    prefixText: 'KES ',
                  ),
                  validator: (value) {
                    final error = TransactionValidation.validateAmount(value);
                    if (error != null) {
                      return error;
                    }
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed != null &&
                        parsed > TransactionValidation.maxAmount) {
                      return 'Amount must be greater than 0 and fit NUMERIC(12,2).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PaymentMethodField(
                  value: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value),
                  validator: TransactionValidation.validatePaymentMethod,
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expense Date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: TransactionValidation.maxDescriptionLength,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Vendor or payment reference',
                    counterText: TransactionValidation.descriptionRemainingText(
                      _descriptionController.text,
                    ),
                  ),
                  validator: TransactionValidation.validateDescription,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _confirmDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF8A80),
                            side: const BorderSide(color: Color(0xFFFF8A80)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                        ),
                      ),
                    if (isEditing) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'Saving...'
                              : (isEditing ? 'Update' : 'Save'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
