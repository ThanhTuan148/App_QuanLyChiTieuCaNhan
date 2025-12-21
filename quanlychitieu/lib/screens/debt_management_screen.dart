/// Màn hình Quản lý Nợ cá nhân
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../models/debt.dart';
import 'add_debt_screen.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Đảm bảo stream được khởi tạo khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final debtProvider = context.read<DebtProvider>();
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.currentUser?.id;
        debugPrint('DebtManagementScreen: Current userId: $userId');
        debugPrint('DebtManagementScreen: Current debts count: ${debtProvider.debts.length}');
        // Force refresh để đảm bảo stream hoạt động
        debtProvider.refreshDebts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nợ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDebtScreen()),
              );
              // Refresh debts after returning
              if (context.mounted) {
                // Stream sẽ tự động cập nhật, nhưng đảm bảo provider được refresh
                context.read<DebtProvider>().notifyListeners();
              }
            },
            tooltip: 'Thêm khoản nợ',
          ),
        ],
      ),
      body: Consumer<DebtProvider>(
        builder: (context, debtProvider, child) {
          // Debug: In ra số lượng debts
          debugPrint('DebtManagementScreen: Building with ${debtProvider.debts.length} debts');
          
          if (debtProvider.debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn không có khoản nợ nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thêm khoản nợ để theo dõi và quản lý',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final analysis = debtProvider.analyzeDebts();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(analysis),
                const SizedBox(height: 16),

                // Overdue debts warning
                if (debtProvider.overdueDebts.isNotEmpty) ...[
                  _buildOverdueWarning(debtProvider.overdueDebts),
                  const SizedBox(height: 16),
                ],

                // Debt list
                const Text(
                  'Danh sách Nợ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...debtProvider.debts.map((debt) => _buildDebtCard(context, debt)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> analysis) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan Nợ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Tổng số dư nợ',
              _formatCurrency(analysis['totalDebt']),
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Thanh toán hàng tháng',
              _formatCurrency(analysis['monthlyPayment']),
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Lãi suất hàng tháng',
              _formatCurrency(analysis['totalInterest']),
              Colors.purple,
            ),
            const Divider(),
            Text(
              analysis['suggestion'],
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueWarning(List<Debt> overdueDebts) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cảnh báo: ${overdueDebts.length} khoản nợ quá hạn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cần xử lý ngay để tránh phí phạt',
                    style: TextStyle(fontSize: 12, color: Colors.red[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt) {
    final isOverdue = debt.isOverdue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDebtTypeColor(debt.type),
          child: Icon(_getDebtTypeIcon(debt.type), color: Colors.white),
        ),
        title: Text(
          debt.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.red[900] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số dư: ${_formatCurrency(debt.currentBalance)}'),
            Text('Lãi suất: ${debt.interestRate}%/năm'),
            if (debt.dueDate != null)
              Text(
                'Đáo hạn: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}',
                style: TextStyle(
                  color: isOverdue ? Colors.red[700] : Colors.grey[600],
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (isOverdue && debt.daysOverdue != null)
              Text(
                'Quá hạn ${debt.daysOverdue} ngày',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Thanh toán'),
              onTap: () => _showPaymentDialog(context, debt),
            ),
            PopupMenuItem(
              child: const Text('Sửa'),
              onTap: () {
                // TODO: Navigate to edit screen
              },
            ),
            PopupMenuItem(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmDelete(context, debt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getDebtTypeColor(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Colors.blue;
      case DebtType.personalLoan:
        return Colors.orange;
      case DebtType.mortgage:
        return Colors.purple;
      case DebtType.other:
        return Colors.grey;
    }
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.account_balance;
      case DebtType.mortgage:
        return Icons.home;
      case DebtType.other:
        return Icons.receipt;
    }
  }

  void _showPaymentDialog(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thanh toán: ${debt.name}'),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: 'Số tiền thanh toán',
            hintText: 'Nhập số tiền',
            prefixText: 'VND ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                context.read<DebtProvider>().makePayment(
                      debtId: debt.id!,
                      amount: amount,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã ghi nhận thanh toán')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khoản nợ "${debt.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DebtProvider>().deleteDebt(debt.id!);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} VND';
  }
}

