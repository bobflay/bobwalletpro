import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl = 'https://bobwallet.xpertbot.online';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  static String _getDeviceName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Flutter App';
  }

  // ============ Authentication ============
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {
          'email': email,
          'password': password,
          'device_name': _getDeviceName(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error');
    }
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Logout failed');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/user');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get user');
    }
  }

  // ============ Wallets ============
  static Future<List<dynamic>> getWallets() async {
    try {
      final response = await _dio.get('/api/wallets');
      return response.data is List ? response.data : response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get wallets');
    }
  }

  static Future<Map<String, dynamic>> createWallet(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/wallets', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create wallet');
    }
  }

  static Future<Map<String, dynamic>> updateWallet(int walletId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/api/wallets/$walletId', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update wallet');
    }
  }

  static Future<void> deleteWallet(int walletId) async {
    try {
      await _dio.delete('/api/wallets/$walletId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete wallet');
    }
  }

  static Future<void> toggleWalletVisibility(int walletId) async {
    try {
      await _dio.patch('/api/wallets/$walletId/toggle-visibility');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to toggle visibility');
    }
  }

  // ============ Transactions ============
  static Future<List<dynamic>> getTransactions(int walletId) async {
    try {
      final response = await _dio.get('/api/wallets/$walletId/transactions');
      return response.data is List ? response.data : response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get transactions');
    }
  }

  static Future<Map<String, dynamic>> createTransaction(int walletId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/wallets/$walletId/transactions', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create transaction');
    }
  }

  static Future<void> deleteTransaction(int walletId, int transactionId) async {
    try {
      await _dio.delete('/api/wallets/$walletId/transactions/$transactionId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete transaction');
    }
  }

  // ============ Income ============
  static Future<List<dynamic>> getIncome() async {
    try {
      final response = await _dio.get('/api/income');
      return response.data is List ? response.data : response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get income');
    }
  }

  static Future<Map<String, dynamic>> createIncome(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/income', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create income');
    }
  }

  static Future<Map<String, dynamic>> updateIncome(int incomeId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/api/income/$incomeId', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update income');
    }
  }

  static Future<void> deleteIncome(int incomeId) async {
    try {
      await _dio.delete('/api/income/$incomeId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete income');
    }
  }

  // ============ Expenses ============
  static Future<List<dynamic>> getExpenses() async {
    try {
      final response = await _dio.get('/api/expenses');
      return response.data is List ? response.data : response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get expenses');
    }
  }

  static Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/expenses', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create expense');
    }
  }

  static Future<Map<String, dynamic>> updateExpense(int expenseId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/api/expenses/$expenseId', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update expense');
    }
  }

  static Future<void> deleteExpense(int expenseId) async {
    try {
      await _dio.delete('/api/expenses/$expenseId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete expense');
    }
  }

  // ============ Assets ============
  static Future<List<dynamic>> getAssets() async {
    try {
      final response = await _dio.get('/api/assets');
      return response.data is List ? response.data : response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get assets');
    }
  }

  static Future<Map<String, dynamic>> createAsset(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/assets', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create asset');
    }
  }

  static Future<Map<String, dynamic>> updateAsset(int assetId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/api/assets/$assetId', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update asset');
    }
  }

  static Future<void> deleteAsset(int assetId) async {
    try {
      await _dio.delete('/api/assets/$assetId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete asset');
    }
  }

  // ============ Settings ============
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/api/settings');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get settings');
    }
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/settings', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update settings');
    }
  }

  // ============ Utilities ============
  static Future<void> seedData() async {
    try {
      await _dio.post('/api/seed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to seed data');
    }
  }

  static Future<Map<String, dynamic>> getAiAnalysis() async {
    try {
      final response = await _dio.post('/api/ai/analyze');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get AI analysis');
    }
  }
}
