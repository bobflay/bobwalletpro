import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'wallets_page.dart';
import 'income_page.dart';
import 'expenses_page.dart';
import 'assets_page.dart';
import 'settings_page.dart';
import 'transactions_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;
  bool _isLoggingOut = false;

  List<Wallet> _wallets = [];
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<Asset> _assets = [];
  List<_DashboardTransaction> _recentTransactions = [];

  String _displayCurrency = 'USD';
  double _usdToFcfa = 600;
  double _eurToFcfa = 655;
  double _usdToEur = 0.92;
  bool _hideValues = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        AuthService.getUserName(),
        AuthService.getUserEmail(),
        ApiService.getWallets(),
        ApiService.getIncome(),
        ApiService.getExpenses(),
        ApiService.getAssets(),
        ApiService.getSettings(),
      ]);

      if (mounted) {
        final settings = results[6] as Map<String, dynamic>;
        final wallets = (results[2] as List)
            .map((j) => Wallet.fromJson(j))
            .toList();

        // Fetch transactions for all wallets in parallel
        final txResults = await Future.wait(
          wallets.map((w) => ApiService.getTransactions(w.id)),
        );

        // Build wallet name lookup and combine transactions
        final walletNameMap = <int, String>{};
        for (final w in wallets) {
          walletNameMap[w.id] = w.name;
        }

        final allTransactions = <_DashboardTransaction>[];
        for (int i = 0; i < wallets.length; i++) {
          final wallet = wallets[i];
          final txList = txResults[i]
              .map((j) => Transaction.fromJson(j))
              .toList();
          for (final tx in txList) {
            allTransactions.add(_DashboardTransaction(
              transaction: tx,
              walletName: wallet.name,
              wallet: wallet,
            ));
          }
        }

        // Sort by created_at descending (fallback to transactionDate) and take latest 50
        allTransactions.sort((a, b) {
          final aDate = a.transaction.createdAt ?? a.transaction.transactionDate;
          final bDate = b.transaction.createdAt ?? b.transaction.transactionDate;
          return bDate.compareTo(aDate);
        });
        final recent = allTransactions.take(50).toList();

        setState(() {
          _userName = (results[0] as String?) ?? '';
          _userEmail = (results[1] as String?) ?? '';
          _wallets = wallets;
          _incomes = (results[3] as List)
              .map((j) => Income.fromJson(j))
              .toList();
          _expenses = (results[4] as List)
              .map((j) => Expense.fromJson(j))
              .toList();
          _assets = (results[5] as List)
              .map((j) => Asset.fromJson(j))
              .toList();
          _recentTransactions = recent;
          _usdToFcfa = (settings['usdToFcfa'] ?? 600).toDouble();
          _eurToFcfa = (settings['eurToFcfa'] ?? 655).toDouble();
          _usdToEur = (settings['usdToEur'] ?? 0.92).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  double _convertToDisplayCurrency(double amount, String fromCurrency) {
    if (fromCurrency == _displayCurrency) return amount;

    // Direct conversions for accuracy
    if (fromCurrency == 'EUR' && _displayCurrency == 'FCFA') {
      return amount * _eurToFcfa;
    }
    if (fromCurrency == 'FCFA' && _displayCurrency == 'EUR') {
      return _eurToFcfa > 0 ? amount / _eurToFcfa : amount;
    }

    // Convert to USD first as base
    double inUsd;
    switch (fromCurrency) {
      case 'USD':
        inUsd = amount;
        break;
      case 'EUR':
        inUsd = _usdToEur > 0 ? amount / _usdToEur : amount;
        break;
      case 'FCFA':
        inUsd = _usdToFcfa > 0 ? amount / _usdToFcfa : amount;
        break;
      default:
        inUsd = amount;
    }
    // Convert from USD to target
    switch (_displayCurrency) {
      case 'USD':
        return inUsd;
      case 'EUR':
        return inUsd * _usdToEur;
      case 'FCFA':
        return inUsd * _usdToFcfa;
      default:
        return inUsd;
    }
  }

  double _sumConverted(List<MapEntry<double, String>> items) {
    double total = 0;
    for (final item in items) {
      total += _convertToDisplayCurrency(item.key, item.value);
    }
    return total;
  }

  String _formatTotal(double value) {
    if (_hideValues) return '****** $_displayCurrency';
    return '${_formatNumber(value)} $_displayCurrency';
  }

  String _maskedNumber(double value) {
    if (_hideValues) return '******';
    return _formatNumber(value);
  }

  String _formatNumber(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(intPart[i]);
    }
    final result = buffer.toString();
    if (decPart == '00') {
      return '${isNegative ? '-' : ''}$result';
    }
    return '${isNegative ? '-' : ''}$result.$decPart';
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await ApiService.logout();
      await AuthService.clearAll();
      ApiService.clearToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      await AuthService.clearAll();
      ApiService.clearToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  IconData _walletTypeIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'mobile':
        return Icons.phone_android;
      case 'wise':
        return Icons.language;
      case 'investment':
        return Icons.show_chart;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletTotal = _sumConverted(
      _wallets.where((w) => !w.isHidden).map((w) => MapEntry(w.balance, w.currency)).toList(),
    );
    final incomeTotal = _sumConverted(
      _incomes.map((i) => MapEntry(i.amount, i.currency)).toList(),
    );
    final expenseTotal = _sumConverted(
      _expenses.map((e) => MapEntry(e.amount, e.currency)).toList(),
    );
    final assetTotal = _sumConverted(
      _assets.map((a) => MapEntry(a.value, a.currency)).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['USD', 'EUR', 'FCFA'].map((currency) {
                final isSelected = _displayCurrency == currency;
                return GestureDetector(
                  onTap: () => setState(() => _displayCurrency = currency),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.deepPurple,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 4),
          _isLoggingOut
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Balance Card
                    _buildHeroCard(walletTotal, assetTotal),
                    const SizedBox(height: 20),

                    // Financial Summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Income',
                            Icons.arrow_upward_rounded,
                            Colors.green,
                            incomeTotal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            'Expenses',
                            Icons.arrow_downward_rounded,
                            Colors.red,
                            expenseTotal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            'Assets',
                            Icons.diamond_outlined,
                            Colors.amber.shade700,
                            assetTotal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // My Wallets Section
                    _buildWalletsSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    _buildRecentTransactions(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroCard(double total, double assetTotal) {
    final netWorth = total + assetTotal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_userName',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Net Worth',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTotal(netWorth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _hideValues = !_hideValues),
                child: Icon(
                  _hideValues ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatTotal(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    IconData icon,
    Color color,
    double total,
  ) {
    return GestureDetector(
      onTap: () {
        Widget page;
        if (title == 'Income') {
          page = const IncomePage();
        } else if (title == 'Expenses') {
          page = const ExpensesPage();
        } else {
          page = const AssetsPage();
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTotal(total),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[850],
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsSection() {
    final visibleWallets = _wallets.where((w) => !w.isHidden).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Wallets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletsPage()),
              ),
              child: Text(
                'See All',
                style: TextStyle(
                  color: Colors.deepPurple[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleWallets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No wallets yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: visibleWallets.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < visibleWallets.length - 1 ? 12 : 0),
                  child: _buildWalletCard(visibleWallets[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _walletTypeColor(String type) {
    switch (type) {
      case 'bank':
        return const Color(0xFF3B82F6);
      case 'cash':
        return const Color(0xFF1A1A2E);
      case 'mobile':
        return const Color(0xFF8B5CF6);
      case 'wise':
        return const Color(0xFF06B6D4);
      case 'investment':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _buildWalletCard(Wallet wallet) {
    final cardColor = _walletTypeColor(wallet.type);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletsPage()),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _walletTypeIcon(wallet.type),
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.currency,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _maskedNumber(wallet.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_recentTransactions.length} latest',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: Colors.grey[200],
                indent: 70,
              ),
              itemBuilder: (context, index) {
                final item = _recentTransactions[index];
                final tx = item.transaction;
                final isCredit = tx.type == 'credit';
                final date = tx.createdAt ?? tx.transactionDate;
                final dateStr =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionsPage(wallet: item.wallet),
                    ),
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: index == _recentTransactions.length - 1
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _walletTypeColor(item.wallet.type)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _walletTypeIcon(item.wallet.type),
                            color: _walletTypeColor(item.wallet.type),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.notes != null && tx.notes!.isNotEmpty
                                    ? tx.notes!
                                    : '${isCredit ? 'Credit' : 'Debit'} - ${item.walletName}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.walletName} · $dateStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _walletTypeColor(item.wallet.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isCredit ? '+' : '-'}${_hideValues ? '******' : _formatNumber(tx.amount)} ${tx.currency}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Wallets', Icons.account_balance_wallet_rounded, Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletsPage()))),
      _QuickAction('Income', Icons.trending_up_rounded, Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomePage()))),
      _QuickAction('Expenses', Icons.trending_down_rounded, Colors.red,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesPage()))),
      _QuickAction('Assets', Icons.diamond_rounded, Colors.amber.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetsPage()))),
      _QuickAction('Settings', Icons.settings_rounded, Colors.grey.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        return GestureDetector(
          onTap: action.onTap,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _DashboardTransaction {
  final Transaction transaction;
  final String walletName;
  final Wallet wallet;

  _DashboardTransaction({
    required this.transaction,
    required this.walletName,
    required this.wallet,
  });
}
