class ExpensePage {
  const ExpensePage({
    required this.items,
    required this.hasMore,
    required this.total,
    required this.page,
    required this.limit,
    this.totalPages = 0,
  });

  final List<ExpenseRecord> items;
  final bool hasMore;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory ExpensePage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    final pageInfo = pagination is Map ? Map<String, dynamic>.from(pagination) : null;
    final data = _extractList(json);
    final int pageNumber = pageInfo != null
        ? _asInt(pageInfo['page'], _asInt(json['page'], 1))
        : _asInt(json['page'], 1);
    final int pageLimit = pageInfo != null
        ? _asInt(pageInfo['limit'], _asInt(json['limit'], 20))
        : _asInt(json['limit'], 20);
    final int totalCount = pageInfo != null
        ? _asInt(pageInfo['total'], _asInt(json['total'], data.length))
        : _asInt(json['total'], data.length);
    final int totalPages = pageInfo != null
        ? _asInt(pageInfo['totalPages'], _asInt(json['totalPages'], totalCount > 0 ? ((totalCount + pageLimit - 1) ~/ pageLimit) : 0))
        : _asInt(json['totalPages'], totalCount > 0 ? ((totalCount + pageLimit - 1) ~/ pageLimit) : 0);
    final bool hasMoreValue = totalPages > 0 ? pageNumber < totalPages : false;

    return ExpensePage(
      items: data
          .map((item) => ExpenseRecord.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      hasMore: hasMoreValue,
      total: totalCount,
      page: pageNumber,
      limit: pageLimit,
      totalPages: totalPages,
    );
  }

  static List<dynamic> _extractList(Map<String, dynamic> json) {
    final candidates = [
      json['items'],
      json['expenses'],
      json['data'],
      json['records'],
      json['results'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) return candidate;
      if (candidate is Map && candidate['items'] is List) return candidate['items'] as List;
      if (candidate is Map && candidate['data'] is List) return candidate['data'] as List;
    }

    return const <dynamic>[];
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.description,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final String? description;
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    final dateValue = json['expense_date'] ?? json['date'] ?? json['created_at'];
    final rawTitle = json['title'] ?? json['name'] ?? 'Expense';
    final rawCategory = json['category'] ?? json['type'] ?? 'General';
    final rawPaymentMethod = json['payment_method'];

    return ExpenseRecord(
      id: (json['id'] ?? json['expense_id'] ?? json['_id'] ?? '').toString(),
      title: rawTitle.toString(),
      amount: _asDouble(json['amount'] ?? json['total']),
      category: rawCategory.toString(),
      expenseDate: _asDate(dateValue) ?? DateTime.now(),
      description: json['description'] is String ? json['description'] as String : null,
      paymentMethod: _asNullableString(rawPaymentMethod),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'amount': amount,
      'category': category.trim(),
      'expense_date': _formatDate(expenseDate),
    };

    final trimmedPaymentMethod = paymentMethod?.trim();
    if (trimmedPaymentMethod != null && trimmedPaymentMethod.isNotEmpty) {
      payload['payment_method'] = trimmedPaymentMethod;
    }

    if ((description ?? '').trim().isNotEmpty) {
      payload['description'] = description!.trim();
    }

    return payload;
  }

  Map<String, dynamic> toUpdateJson() {
    return toCreateJson();
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
