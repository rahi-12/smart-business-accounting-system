import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/customer.dart';
import '../../utils/customer_validation.dart';
import '../../view_models/customer_view_model.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({
    super.key,
    required this.viewModel,
    this.customer,
  });

  final CustomerViewModel viewModel;
  final CustomerRecord? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String? _duplicateEmailMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer != null) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
      _notesController.text = customer.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final validationMessage = CustomerValidation.validateEmail(value);
    if (validationMessage != null) {
      return validationMessage;
    }
    if (_duplicateEmailMessage != null) {
      final message = _duplicateEmailMessage;
      _duplicateEmailMessage = null;
      return message;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.viewModel.saveCustomer(
      id: widget.customer?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = false);
    final message = widget.viewModel.errorMessage ?? 'Unable to save customer.';
    if (message.toLowerCase().contains('already exists')) {
      setState(() => _duplicateEmailMessage = message);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      backgroundColor: const Color(0xFF07130E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F18),
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Edit customer' : 'Add customer'),
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
                  isEditing ? 'Update customer details' : 'Add customer',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  maxLength: CustomerValidation.maxNameLength,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Jane Doe',
                  ),
                  validator: CustomerValidation.validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  maxLength: CustomerValidation.maxPhoneLength,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\n')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: '+254 712 345 678',
                  ),
                  validator: CustomerValidation.validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  maxLength: CustomerValidation.maxEmailLength,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'jane@example.com',
                  ),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLength: CustomerValidation.maxAddressLength,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    hintText: 'Nairobi, Kenya',
                  ),
                  validator: CustomerValidation.validateAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLength: CustomerValidation.maxNotesLength,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    counterText: CustomerValidation.notesRemainingText(
                      _notesController.text,
                    ),
                  ),
                  validator: CustomerValidation.validateNotes,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Saving...'
                        : (isEditing ? 'Update customer' : 'Save customer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
