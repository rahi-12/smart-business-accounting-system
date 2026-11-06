class DashboardSummary {
  const DashboardSummary({
    required this.summary,
    required this.recentTransactions,
    required this.monthlySummary,
  });

  final DashboardSummaryTotals summary;
  final List<DashboardTransaction> recentTransactions;
  final List<DashboardMonthlySummary> monthlySummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'];
    final transactionsJson = json['recent_transactions'];
    final monthlyJson = json['monthly_summary'];

    return DashboardSummary(
      summary: DashboardSummaryTotals.fromJson(
        summaryJson is Map<String, dynamic>
            ? summaryJson
            : Map<String, dynamic>.from(summaryJson ?? const {}),
      ),
      recentTransactions: (transactionsJson is List)
          ? transactionsJson
                .map(
                  (item) => DashboardTransaction.fromJson(
                    Map<String, dynamic>.from(item ?? const {}),
                  ),
                )
                .toList()
          : const [],
      monthlySummary: (monthlyJson is List)
          ? monthlyJson
                .map(
                  (item) => DashboardMonthlySummary.fromJson(
                    Map<String, dynamic>.from(item ?? const {}),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class DashboardSummaryTotals {
  const DashboardSummaryTotals({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
  });

  final double totalIncome;
  final double totalExpenses;
  final double netProfit;

  factory DashboardSummaryTotals.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryTotals(
      totalIncome: _toDouble(json['total_income']),
      totalExpenses: _toDouble(json['total_expenses']),
      netProfit: _toDouble(json['net_profit']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class DashboardTransaction {
  const DashboardTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.transactionDate,
    required this.description,
  });

  final String id;
  final String type;
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final DateTime? transactionDate;
  final String? description;

  factory DashboardTransaction.fromJson(Map<String, dynamic> json) {
    final dateValue = json['transaction_date'];

    return DashboardTransaction(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      category: (json['category'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      transactionDate: dateValue is String && dateValue.isNotEmpty
          ? DateTime.tryParse(dateValue)
          : null,
      description: json['description'] is String
          ? json['description'] as String
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class DashboardMonthlySummary {
  const DashboardMonthlySummary({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
  });

  final String month;
  final double income;
  final double expenses;
  final double net;

  factory DashboardMonthlySummary.fromJson(Map<String, dynamic> json) {
    return DashboardMonthlySummary(
      month: (json['month'] ?? '').toString(),
      income: _toDouble(json['income']),
      expenses: _toDouble(json['expenses']),
      net: _toDouble(json['net']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
