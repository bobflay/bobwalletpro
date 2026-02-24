import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'wallets_page.dart';
import 'income_page.dart';
import 'expenses_page.dart';
import 'assets_page.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();
    if (mounted) {
      setState(() {
        _userName = name ?? '';
        _userEmail = email ?? '';
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _isLoading
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, $_userName!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  'Wallets',
                  Icons.account_balance_wallet,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletsPage()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Income',
                  Icons.trending_up,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncomePage()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Expenses',
                  Icons.trending_down,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesPage()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Assets',
                  Icons.diamond,
                  Colors.amber,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssetsPage()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
