import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/dashboard_summary.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/user_profile.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode = 0]);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ProfileNotFoundException extends ApiException {
  ProfileNotFoundException() : super('Profile not found.', 404);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([
    String message = 'Invalid or expired authentication token.',
  ]) : super(message, 401);
}

class ApiService {
  Future<UserProfile> getProfile() async {
    final response = await _sendRequest('GET', '/api/auth/profile');
    final payload = _decodeBody(response.body);
    final userData = payload['user'];
    if (userData is! Map) {
      throw ProfileNotFoundException();
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(userData));
  }

  Future<UserProfile> registerProfile({
    required String fullName,
    required String username,
  }) async {
    final response = await _sendRequest(
      'POST',
      '/api/auth/register',
      body: {'fullName': fullName.trim(), 'username': username.trim()},
    );

    final payload = _decodeBody(response.body);
    final userData = payload['user'];
    if (userData is! Map) {
      throw ApiException('Profile registration failed.', response.statusCode);
    }

    return UserProfile.fromJson(Map<String, dynamic>.from(userData));
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final response = await _sendRequest('GET', '/api/dashboard/summary');
    final payload = _decodeBody(response.body);
    final data = payload['data'];

    if (data is! Map) {
      throw ApiException('Dashboard summary unavailable.', response.statusCode);
    }

    return DashboardSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<IncomePage> getIncomes({Map<String, String>? queryParameters}) async {
    final query = queryParameters == null || queryParameters.isEmpty
        ? ''
        : '?${queryParameters.entries.map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}').join('&')}';

    final response = await _sendRequest('GET', '/api/income$query');
    final payload = _decodeBody(response.body);
    final data = payload['data'] ?? payload;

    if (data is! Map) {
      throw ApiException(
        'Income records could not be loaded.',
        response.statusCode,
      );
    }

    return IncomePage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<IncomeRecord> createIncome({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    final normalizedDescription = _normalizeDescription(description);
    final body = {
      'title': title.trim(),
      'category': category.trim(),
      'amount': amount,
      'income_date': _formatDate(date),
      'payment_method': paymentMethod.trim(),
      'description': normalizedDescription,
    };

    final response = await _sendRequest('POST', '/api/income', body: body);
    final payload = _decodeBody(response.body);
    final data = payload['data'] ?? payload;

    if (data is! Map) {
      throw ApiException('Income could not be created.', response.statusCode);
    }

    return IncomeRecord.fromJson(Map<String, dynamic>.from(data));
  }

  Future<IncomeRecord> updateIncome({
    required String id,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    final normalizedDescription = _normalizeDescription(description);
    final body = {
      'title': title.trim(),
      'category': category.trim(),
      'amount': amount,
      'income_date': _formatDate(date),
      'payment_method': paymentMethod.trim(),
      'description': normalizedDescription,
    };

    final response = await _sendRequest('PUT', '/api/income/$id', body: body);
    final payload = _decodeBody(response.body);
    final data = payload['data'] ?? payload;

    if (data is! Map) {
      throw ApiException('Income could not be updated.', response.statusCode);
    }

    return IncomeRecord.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteIncome(String id) async {
    await _sendRequest('DELETE', '/api/income/$id');
  }

  Future<ExpensePage> getExpenses({
    Map<String, String>? queryParameters,
  }) async {
    final query = queryParameters == null || queryParameters.isEmpty
        ? ''
        : '?${queryParameters.entries.map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}').join('&')}';

    final response = await _sendRequest('GET', '/api/expenses$query');
    final payload = _decodeBody(response.body);
    final data = payload['data'] ?? payload;

    if (data is! Map) {
      throw ApiException(
        'Expense records could not be loaded.',
        response.statusCode,
      );
    }

    return ExpensePage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ExpenseRecord> createExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    final normalizedDescription = _normalizeDescription(description);
    final body = {
      'title': title.trim(),
      'category': category.trim(),
      'amount': amount,
      'expense_date': _formatDate(date),
      'payment_method': paymentMethod.trim(),
      'description': normalizedDescription,
    };

    final response = await _sendRequest('POST', '/api/expenses', body: body);
    final payload = _decodeBody(response.body);
    final data = payload['data'] ?? payload;

    if (data is! Map) {
      throw ApiException('Expense could not be created.', response.statusCode);
    }

    return ExpenseRecord.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ExpenseRecord> updateExpense({
    required String id,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    final normalizedDescription = _normalizeDescription(description);
    final body = {
      'title': title.trim(),
      'category': category.trim(),
      'amount': amount,
      'expense_date': _formatDate(date),
      'payment_method': paymentMethod.trim(),
      'description': normalizedDescription,
    };

    final response = await _sendRequest('PUT', '/api/expenses/$id', body: body);
    final payload = _decodeBody(response.body);
    final data = payload['data'] ?? payload;

    if (data is! Map) {
      throw ApiException('Expense could not be updated.', response.statusCode);
    }

    return ExpenseRecord.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteExpense(String id) async {
    await _sendRequest('DELETE', '/api/expenses/$id');
  }

  String? _normalizeDescription(String? description) {
    final normalized = description?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<http.Response> _sendRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw UnauthorizedException();
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw UnauthorizedException();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      http.Response response;

      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        throw UnimplementedError('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 404) {
        final payload = _decodeBody(response.body);
        if ((payload['code'] ?? '') == 'PROFILE_NOT_FOUND') {
          throw ProfileNotFoundException();
        }
      }

      if (response.statusCode == 401) {
        final payload = _decodeBody(response.body);
        if ((payload['code'] ?? '') == 'INVALID_TOKEN') {
          throw UnauthorizedException();
        }
      }

      if (response.statusCode >= 400) {
        final payload = _decodeBody(response.body);
        final message = _statusMessage(response.statusCode, payload);
        throw ApiException(message, response.statusCode);
      }

      return response;
    } on SocketException {
      throw ApiException(
        'Cannot reach server. Check your connection or backend status.',
        503,
      );
    } on http.ClientException {
      throw ApiException(
        'Cannot reach server. Check your connection or backend status.',
        503,
      );
    }
  }

  String _statusMessage(int statusCode, Map<String, dynamic> payload) {
    if (statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (statusCode == 404) {
      return 'The requested record could not be found.';
    }
    if (statusCode == 400 || statusCode == 422) {
      final details =
          payload['message'] as String? ??
          payload['error'] as String? ??
          'Please review the form fields and try again.';
      return details;
    }
    if (statusCode >= 500) {
      return 'The server could not process this request right now.';
    }
    return payload['message'] as String? ?? 'Request failed.';
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _decodeBody(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }
}
