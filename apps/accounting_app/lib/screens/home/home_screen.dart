import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/friendly_error.dart';
import '../customer/customer_screen.dart';
import '../expense/expense_screen.dart';
import '../income/income_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  int _selectedIndex = 0;
  bool _isLoading = false;
  DashboardSummary? _dashboardSummary;
  String? _errorMessage;

  final List<_NavItem> _navigationItems = const [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItem(label: 'Income', icon: Icons.trending_up_rounded),
    _NavItem(label: 'Expenses', icon: Icons.payments_rounded),
    _NavItem(label: 'Customers', icon: Icons.people_alt_rounded),
    _NavItem(label: 'Transactions', icon: Icons.swap_horiz_rounded),
    _NavItem(label: 'Reports', icon: Icons.bar_chart_rounded),
  ];

  final List<_ModuleShortcut> _moduleShortcuts = const [
    _ModuleShortcut('Income', Icons.trending_up_rounded, Color(0xFF1E7A5B)),
    _ModuleShortcut('Expenses', Icons.payments_rounded, Color(0xFFDBA13C)),
    _ModuleShortcut('Customers', Icons.people_alt_rounded, Color(0xFF58A6FF)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboard(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadDashboard({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      if (forceRefresh || _errorMessage != null) {
        _errorMessage = null;
      }
    });

    try {
      final summary = await _apiService.getDashboardSummary();
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardSummary = summary;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardSummary = null;
        _errorMessage = friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = switch (_selectedIndex) {
      1 => 'Income',
      2 => 'Expenses',
      3 => 'Customers',
      4 => 'Transactions',
      5 => 'Reports',
      _ => _navigationItems[_selectedIndex].label,
    };

    final currentPage = switch (_selectedIndex) {
      0 => _DashboardContent(
          profile: widget.profile,
          dashboard: _dashboardSummary,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onRetry: () => _loadDashboard(forceRefresh: true),
          moduleShortcuts: _moduleShortcuts,
        ),
      3 => const CustomerScreen(),
      4 => const _ModulePage(
          title: 'Transactions',
          description: 'Coming soon — transaction history and cash movement tools are still in progress.',
          icon: Icons.swap_horiz_rounded,
        ),
      5 => const _ModulePage(
          title: 'Reports',
          description: 'Coming soon — advanced financial reports and insights will be added here.',
          icon: Icons.bar_chart_rounded,
        ),
      _ => _DashboardContent(
          profile: widget.profile,
          dashboard: _dashboardSummary,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onRetry: () => _loadDashboard(forceRefresh: true),
          moduleShortcuts: _moduleShortcuts,
        ),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF07130E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F18),
        foregroundColor: Colors.white,
        title: Text(appBarTitle),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: currentPage,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0E1F18),
        indicatorColor: const Color(0xFF1E7A5B).withAlpha(80),
        surfaceTintColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) async {
          if (index == 1) {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const IncomeScreen()),
            );
            if (result == true) {
              _loadDashboard(forceRefresh: true);
            }
            return;
          }

          if (index == 2) {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ExpenseScreen()),
            );
            if (result == true) {
              _loadDashboard(forceRefresh: true);
            }
            return;
          }

          if (index == 3) {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const CustomerScreen()),
            );
            if (result == true) {
              _loadDashboard(forceRefresh: true);
            }
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _navigationItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.profile,
    required this.dashboard,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.moduleShortcuts,
  });

  final UserProfile profile;
  final DashboardSummary? dashboard;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final List<_ModuleShortcut> moduleShortcuts;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E7A5B)),
        ),
      );
    }

    if (errorMessage != null) {
      return _DashboardErrorState(message: errorMessage!, onRetry: onRetry);
    }

    final data = dashboard;
    if (data == null) {
      return _DashboardEmptyState(onRetry: onRetry);
    }

    final summary = data.summary;
    final recentTransactions = data.recentTransactions;
    final monthlySummary = data.monthlySummary;
    final incomeVsExpense = monthlySummary.isEmpty
        ? const <_TrendPoint>[]
        : monthlySummary
              .map(
                (item) => _TrendPoint(
                  label: item.month.length > 3
                      ? item.month.substring(0, 3)
                      : item.month,
                  income: item.income,
                  expense: item.expenses,
                ),
              )
              .toList();

    final metrics = <_MetricCardData>[
      _MetricCardData(
        label: 'Total income',
        value: _formatCurrency(summary.totalIncome),
        change: 'Current year total',
        accent: const Color(0xFF1E7A5B),
        icon: Icons.arrow_downward_rounded,
      ),
      _MetricCardData(
        label: 'Total expenses',
        value: _formatCurrency(summary.totalExpenses),
        change: 'Current year total',
        accent: const Color(0xFFDBA13C),
        icon: Icons.arrow_upward_rounded,
      ),
      _MetricCardData(
        label: 'Net profit',
        value: _formatCurrency(summary.netProfit),
        change: summary.netProfit >= 0
            ? 'Positive cashflow'
            : 'Negative cashflow',
        accent: summary.netProfit >= 0
            ? const Color(0xFF58B98B)
            : const Color(0xFFFF8A80),
        icon: Icons.trending_up_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(profile: profile),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: metrics
                .map(
                  (metric) =>
                      SizedBox(width: 220, child: _SummaryCard(data: metric)),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF0E1F18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Income vs. expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Current year',
                        style: TextStyle(color: Color(0xFFB0C7B9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (incomeVsExpense.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Text(
                        'No income or expense data for the current year yet.',
                        style: TextStyle(color: Color(0xFFB0C7B9)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: incomeVsExpense.map((point) {
                          final maxValue = incomeVsExpense
                              .map(
                                (item) => item.income > item.expense
                                    ? item.income
                                    : item.expense,
                              )
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble();

                          final incomeHeight = maxValue <= 0
                              ? 0.0
                              : (point.income / maxValue) * 100;
                          final expenseHeight = maxValue <= 0
                              ? 0.0
                              : (point.expense / maxValue) * 100;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 120,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              width: 16,
                                              height: incomeHeight,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF1E7A5B),
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(8),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              width: 16,
                                              height: expenseHeight,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFDBA13C),
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(8),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    point.label,
                                    style: const TextStyle(
                                      color: Color(0xFFB0C7B9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      _LegendDot(color: Color(0xFF1E7A5B)),
                      SizedBox(width: 8),
                      Text('Income', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 18),
                      _LegendDot(color: Color(0xFFDBA13C)),
                      SizedBox(width: 8),
                      Text('Expense', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFF0E1F18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent transactions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (recentTransactions.isEmpty)
                          const Text(
                            'No recent transactions available.',
                            style: TextStyle(color: Color(0xFFB0C7B9)),
                          )
                        else
                          ...recentTransactions.map((transaction) {
                            final isIncome = transaction.type == 'income';
                            final subtitle = [
                              transaction.category,
                              if (transaction.transactionDate != null)
                                _formatDate(transaction.transactionDate!),
                            ].join(' • ');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isIncome
                                          ? const Color(0xFF1E7A5B)
                                                .withAlpha(40)
                                          : const Color(0xFFDBA13C)
                                                .withAlpha(40),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: isIncome
                                          ? const Color(0xFF58B98B)
                                          : const Color(0xFFFFD166),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(
                                            color: Color(0xFFB0C7B9),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isIncome ? "+" : "-"}${_formatCurrency(transaction.amount, includeCurrencySymbol: true, sign: false)}',
                                    style: TextStyle(
                                      color: isIncome
                                          ? const Color(0xFF58B98B)
                                          : const Color(0xFFFFD166),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Card(
                  color: const Color(0xFF0E1F18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly financial summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (monthlySummary.isEmpty)
                          const Text(
                            'No monthly summary yet.',
                            style: TextStyle(color: Color(0xFFB0C7B9)),
                          )
                        else
                          ...monthlySummary.map((item) {
                            final maxValue = monthlySummary
                                .map(
                                  (entry) => entry.income > entry.expenses
                                      ? entry.income
                                      : entry.expenses,
                                )
                                .fold<double>(
                                  0,
                                  (previousValue, element) =>
                                      element > previousValue
                                      ? element
                                      : previousValue,
                                );
                            final progress = maxValue <= 0
                                ? 0.0
                                : (item.income / maxValue).clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.month,
                                        style: const TextStyle(
                                          color: Color(0xFFB0C7B9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'KES ${_formatCurrencyString(item.net, includeCurrencySymbol: false)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF122A22),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progress,
                                        child: Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E7A5B),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF0E1F18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick navigation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: moduleShortcuts.map((shortcut) {
                      final isIncomeShortcut = shortcut.name == 'Income';
                      final isExpenseShortcut = shortcut.name == 'Expenses';
                      final isCustomerShortcut = shortcut.name == 'Customers';
                      return InkWell(
                        onTap: isIncomeShortcut || isExpenseShortcut || isCustomerShortcut
                            ? () async {
                                final homeState = context
                                    .findAncestorStateOfType<_HomeScreenState>();
                                final navigator = Navigator.of(context);
                                final result = await navigator.push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => isIncomeShortcut
                                        ? const IncomeScreen()
                                        : isExpenseShortcut
                                        ? const ExpenseScreen()
                                        : const CustomerScreen(),
                                  ),
                                );
                                if (result == true) {
                                  homeState?._loadDashboard(forceRefresh: true);
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF122A22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: shortcut.color.withAlpha(48),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  shortcut.icon,
                                  color: shortcut.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  shortcut.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(
    double value, {
    bool includeCurrencySymbol = true,
    bool sign = true,
  }) {
    final rounded = value.round();
    final formattedValue = rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    if (!includeCurrencySymbol) {
      return formattedValue;
    }

    final prefix = sign && value >= 0 ? 'KES ' : (sign ? '-KES ' : 'KES ');
    return '$prefix$formattedValue';
  }

  static String _formatCurrencyString(
    double value, {
    bool includeCurrencySymbol = true,
  }) {
    return _formatCurrency(
      value,
      includeCurrencySymbol: includeCurrencySymbol,
      sign: false,
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: const Color(0xFF0E1F18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No dashboard data yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'There are no income or expense records for this account yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB0C7B9)),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7A5B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: const Color(0xFF0E1F18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFFD166),
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7A5B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF103726), Color(0xFF1E7A5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning,',
                  style: TextStyle(color: Color(0xFFCCFBEA), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your business is growing steadily this month.',
                  style: TextStyle(color: Color(0xFFEAFBF4)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Current year',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _MetricCardData data;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(color: Color(0xFFB0C7B9)),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: data.accent.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.change,
              style: TextStyle(color: data.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModulePage extends StatelessWidget {
  const _ModulePage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: const Color(0xFF0E1F18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E7A5B).withAlpha(40),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 32, color: const Color(0xFF58B98B)),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB0C7B9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _ModuleShortcut {
  const _ModuleShortcut(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.change,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final String change;
  final Color accent;
  final IconData icon;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}
