import 'package:flutter/material.dart';

class PaymentMethodField extends StatelessWidget {
  const PaymentMethodField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  static const List<String> options = <String>[
    'Cash',
    'Bank Transfer',
    'Mobile Money',
    'Card',
  ];

  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final sanitizedValue = value?.trim();
    final values = <String>{
      ...options,
      if (sanitizedValue != null && sanitizedValue.isNotEmpty) sanitizedValue,
    }.toList();

    return DropdownButtonFormField<String>(
      initialValue: sanitizedValue != null && sanitizedValue.isNotEmpty ? sanitizedValue : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Payment method',
        hintText: 'Select a method',
      ),
      dropdownColor: const Color(0xFF0E1F18),
      items: values
          .map(
            (method) => DropdownMenuItem<String>(
              value: method,
              child: Text(method),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
    );
  }
}
