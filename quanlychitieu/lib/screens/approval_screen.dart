/// Màn hình phê duyệt giao dịch
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/group.dart';
import '../models/approval_request.dart';
import '../models/expense.dart';

class ApprovalScreen extends StatelessWidget {
  final Group group;

  const ApprovalScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phê duyệt giao dịch'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          final pendingApprovals = groupProvider.pendingApprovals
              .where((a) => a.groupId == group.id)
              .toList();

          if (pendingApprovals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có giao dịch nào cần phê duyệt',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: pendingApprovals.length,
            itemBuilder: (context, index) {
              return _ApprovalCard(
                approval: pendingApprovals[index],
                group: group,
              );
            },
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatefulWidget {
  final ApprovalRequest approval;
  final Group group;

  const _ApprovalCard({
    required this.approval,
    required this.group,
  });

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _isLoading = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await context.read<GroupProvider>().approveExpense(
            approvalRequestId: widget.approval.id!,
            expenseId: widget.approval.expenseId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã phê duyệt giao dịch'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập lý do từ chối'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<GroupProvider>().rejectExpense(
            approvalRequestId: widget.approval.id!,
            reason: _reasonController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối giao dịch'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => _ExpenseDetailDialog(
        approval: widget.approval,
        onApprove: _approve,
        onReject: _reject,
        reasonController: _reasonController,
        isLoading: _isLoading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final expense = expenseProvider.expenses
            .firstWhere((e) => e.id == widget.approval.expenseId,
                orElse: () => Expense(
                      amount: 0,
                      description: 'Đang tải...',
                      date: DateTime.now(),
                      categoryId: '',
                      isIncome: false,
                      userId: '',
                    ));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: _showDetailDialog,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expense.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chờ phê duyệt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Số tiền: ${_formatCurrency(expense.amount)} VND',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày: ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Phê duyệt'),
                        onPressed: _isLoading ? null : _approve,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Từ chối'),
                        onPressed: _isLoading ? null : _showDetailDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }
}

class _ExpenseDetailDialog extends StatelessWidget {
  final ApprovalRequest approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final TextEditingController reasonController;
  final bool isLoading;

  const _ExpenseDetailDialog({
    required this.approval,
    required this.onApprove,
    required this.onReject,
    required this.reasonController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chi tiết giao dịch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lý do từ chối (nếu có):'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: isLoading ? null : onReject,
          child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onApprove,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Phê duyệt'),
        ),
      ],
    );
  }
}

