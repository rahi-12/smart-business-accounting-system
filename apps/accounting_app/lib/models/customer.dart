class CustomerPage {
  const CustomerPage({
    required this.items,
    required this.hasMore,
    required this.total,
    required this.page,
    required this.limit,
    this.totalPages = 0,
  });

  final List<CustomerRecord> items;
  final bool hasMore;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory CustomerPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    final pageInfo = pagination is Map ? Map<String, dynamic>.from(pagination) : null;
    final rawItems = _extractList(json);
    final pageNumber = pageInfo != null
        ? _asInt(pageInfo['page'], _asInt(json['page'], 1))
        : _asInt(json['page'], 1);
    final pageLimit = pageInfo != null
        ? _asInt(pageInfo['limit'], _asInt(json['limit'], 20))
        : _asInt(json['limit'], 20);
    final totalCount = pageInfo != null
        ? _asInt(pageInfo['total'], _asInt(json['total'], rawItems.length))
        : _asInt(json['total'], rawItems.length);
    final totalPages = pageInfo != null
        ? _asInt(
            pageInfo['totalPages'],
            _asInt(
              json['totalPages'],
              totalCount > 0 ? ((totalCount + pageLimit - 1) ~/ pageLimit).toInt() : 0,
            ),
          )
        : _asInt(
            json['totalPages'],
            totalCount > 0 ? ((totalCount + pageLimit - 1) ~/ pageLimit).toInt() : 0,
          );

    return CustomerPage(
      items: rawItems
          .map(
            (item) => CustomerRecord.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      hasMore: totalPages > 0 ? pageNumber < totalPages : false,
      total: totalCount,
      page: pageNumber,
      limit: pageLimit,
      totalPages: totalPages,
    );
  }

  static List<dynamic> _extractList(Map<String, dynamic> json) {
    final candidates = [
      json['items'],
      json['customers'],
      json['data'],
      json['records'],
      json['results'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate;
      }
      if (candidate is Map && candidate['items'] is List) {
        return candidate['items'] as List;
      }
      if (candidate is Map && candidate['data'] is List) {
        return candidate['data'] as List;
      }
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

class CustomerRecord {
  const CustomerRecord({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CustomerRecord.fromJson(Map<String, dynamic> json) {
    return CustomerRecord(
      id: (json['id'] ?? json['customer_id'] ?? '').toString(),
      name: (json['name'] ?? json['customer_name'] ?? '').toString(),
      phone: _asNullableString(json['phone']),
      email: _asNullableString(json['email']),
      address: _asNullableString(json['address']),
      notes: _asNullableString(json['notes']),
      isActive: json['is_active'] == true,
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _asDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'phone': _normalizeOptionalText(phone),
      'email': _normalizeOptionalText(email),
      'address': _normalizeOptionalText(address),
      'notes': _normalizeOptionalText(notes),
    };
    return payload;
  }

  Map<String, dynamic> toUpdateJson() => toCreateJson();

  static String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
