import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/firebase_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navigationItems = const [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItem(label: 'Transactions', icon: Icons.swap_horiz_rounded),
    _NavItem(label: 'Invoices', icon: Icons.receipt_long_rounded),
    _NavItem(label: 'Expenses', icon: Icons.payments_rounded),
    _NavItem(label: 'Reports', icon: Icons.bar_chart_rounded),
  ];

  final List<_MetricCardData> _metrics = const [
    _MetricCardData(
      label: 'Total income',
      value: 'KES 284,200',
      change: '+12.8% vs last month',
      accent: Color(0xFF1E7A5B),
      icon: Icons.arrow_downward_rounded,
    ),
    _MetricCardData(
      label: 'Total expenses',
      value: 'KES 198,420',
      change: '+4.2% vs last month',
      accent: Color(0xFFDBA13C),
      icon: Icons.arrow_upward_rounded,
    ),
    _MetricCardData(
      label: 'Net profit',
      value: 'KES 85,780',
      change: '+18.7% vs last month',
      accent: Color(0xFF58B98B),
      icon: Icons.trending_up_rounded,
    ),
  ];

  final List<_TransactionItem> _transactions = const [
    _TransactionItem(
      title: 'Loyalty Client Payment',
      subtitle: 'Sales • Today, 2:45 PM',
      amount: '+KES 24,500',
      isIncome: true,
    ),
    _TransactionItem(
      title: 'Office Rent',
      subtitle: 'Operations • Today, 9:10 AM',
      amount: '-KES 18,200',
      isIncome: false,
    ),
    _TransactionItem(
      title: 'Digital Marketing',
      subtitle: 'Marketing • Yesterday',
      amount: '-KES 7,800',
      isIncome: false,
    ),
    _TransactionItem(
      title: 'Consulting Revenue',
      subtitle: 'Services • Yesterday',
      amount: '+KES 32,100',
      isIncome: true,
    ),
  ];

  final List<_TrendPoint> _incomeVsExpense = const [
    _TrendPoint(label: 'Jan', income: 62, expense: 48),
    _TrendPoint(label: 'Feb', income: 70, expense: 52),
    _TrendPoint(label: 'Mar', income: 68, expense: 58),
    _TrendPoint(label: 'Apr', income: 82, expense: 63),
    _TrendPoint(label: 'May', income: 92, expense: 76),
    _TrendPoint(label: 'Jun', income: 108, expense: 84),
  ];

  final List<_MonthSummary> _monthlySummary = const [
    _MonthSummary(label: 'Jan', income: 56000, expense: 41000),
    _MonthSummary(label: 'Feb', income: 64000, expense: 42000),
    _MonthSummary(label: 'Mar', income: 69000, expense: 47000),
    _MonthSummary(label: 'Apr', income: 82000, expense: 54000),
    _MonthSummary(label: 'May', income: 91000, expense: 61000),
    _MonthSummary(label: 'Jun', income: 102000, expense: 70000),
  ];

  final List<_ModuleShortcut> _moduleShortcuts = const [
    _ModuleShortcut('Sales', Icons.point_of_sale_rounded, Color(0xFF1E7A5B)),
    _ModuleShortcut('Bills', Icons.receipt_rounded, Color(0xFF58B98B)),
    _ModuleShortcut(
      'Budgets',
      Icons.account_balance_wallet_rounded,
      Color(0xFF3AA879),
    ),
    _ModuleShortcut('Settings', Icons.tune_rounded, Color(0xFFB5C9BF)),
  ];

  Future<void> _signOut() async {
    await FirebaseAuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardContent(
        profile: widget.profile,
        metrics: _metrics,
        transactions: _transactions,
        incomeVsExpense: _incomeVsExpense,
        monthlySummary: _monthlySummary,
        moduleShortcuts: _moduleShortcuts,
      ),
      const _ModulePage(
        title: 'Transactions',
        description: 'Track sales, expenses, and cash movement across all active accounts.',
        icon: Icons.swap_horiz_rounded,
      ),
      const _ModulePage(
        title: 'Invoices',
        description: 'Review outstanding invoices, issue new ones, and monitor collections.',
        icon: Icons.receipt_long_rounded,
      ),
      const _ModulePage(
        title: 'Expenses',
        description:
            'Monitor vendor payments, payroll costs, and operating overheads.',
        icon: Icons.payments_rounded,
      ),
      const _ModulePage(
        title: 'Reports',
        description: 'Analyse profit trends, equipment usage, and yearly comparison reports.',
        icon: Icons.bar_chart_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF07130E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F18),
        foregroundColor: Colors.white,
        title: Text(_navigationItems[_selectedIndex].label),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0E1F18),
        indicatorColor: const Color(0xFF1E7A5B).withAlpha(80),
        surfaceTintColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
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
    required this.metrics,
    required this.transactions,
    required this.incomeVsExpense,
    required this.monthlySummary,
    required this.moduleShortcuts,
  });

  final UserProfile profile;
  final List<_MetricCardData> metrics;
  final List<_TransactionItem> transactions;
  final List<_TrendPoint> incomeVsExpense;
  final List<_MonthSummary> monthlySummary;
  final List<_ModuleShortcut> moduleShortcuts;

  @override
  Widget build(BuildContext context) {
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
                        'This half-year',
                        style: TextStyle(color: Color(0xFFB0C7B9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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

                        final incomeHeight = (point.income / maxValue) * 100;
                        final expenseHeight = (point.expense / maxValue) * 100;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 120,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                        ...transactions.map(
                          (transaction) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: transaction.isIncome
                                        ? const Color(0xFF1E7A5B).withAlpha(40)
                                        : const Color(0xFFDBA13C).withAlpha(40),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    transaction.isIncome
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: transaction.isIncome
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
                                        transaction.subtitle,
                                        style: const TextStyle(
                                          color: Color(0xFFB0C7B9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  transaction.amount,
                                  style: TextStyle(
                                    color: transaction.isIncome
                                        ? const Color(0xFF58B98B)
                                        : const Color(0xFFFFD166),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                        ...monthlySummary.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        color: Color(0xFFB0C7B9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'KES ${item.net.toStringAsFixed(0)}',
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
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: item.progress,
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
                          ),
                        ),
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
                      return Container(
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
                              child: Icon(shortcut.icon, color: shortcut.color),
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
              'Q3 Snapshot',
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

class _TransactionItem {
  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
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

class _MonthSummary {
  const _MonthSummary({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;

  double get net => income - expense;

  double get progress => (income / 120000).clamp(0.0, 1.0);
}
