/// Màn hình thêm/sửa khoản nợ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../models/debt.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debt;

  const AddDebtScreen({super.key, this.debt});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  final _balanceController = TextEditingController();
  final _interestController = TextEditingController();
  final _creditorController = TextEditingController();
  final _descriptionController = TextEditingController();

  DebtType _selectedType = DebtType.creditCard;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      final debt = widget.debt!;
      _nameController.text = debt.name;
      _principalController.text = debt.principalAmount.toString();
      _balanceController.text = debt.currentBalance.toString();
      _interestController.text = debt.interestRate.toString();
      _creditorController.text = debt.creditor ?? '';
      _descriptionController.text = debt.description ?? '';
      _selectedType = debt.type;
      _startDate = debt.startDate;
      _dueDate = debt.dueDate;
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _balanceController.dispose();
    _interestController.dispose();
    _creditorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người dùng chưa đăng nhập')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final debt = Debt(
      id: widget.debt?.id,
      userId: userId,
      name: _nameController.text.trim(),
      type: _selectedType,
      principalAmount: double.parse(_principalController.text),
      currentBalance: double.parse(_balanceController.text),
      interestRate: double.parse(_interestController.text),
      startDate: _startDate ?? DateTime.now(),
      dueDate: _dueDate,
      status: widget.debt?.status ?? DebtStatus.active,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      creditor: _creditorController.text.trim().isEmpty
          ? null
          : _creditorController.text.trim(),
    );

    try {
      final debtProvider = context.read<DebtProvider>();
      if (widget.debt == null) {
        await debtProvider.addDebt(debt);
      } else {
        await debtProvider.updateDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.debt == null
                ? 'Đã thêm khoản nợ'
                : 'Đã cập nhật khoản nợ'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debt == null ? 'Thêm Khoản Nợ' : 'Sửa Khoản Nợ'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveDebt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khoản nợ *',
                  hintText: 'Ví dụ: Thẻ tín dụng Vietcombank',
                  prefixIcon: Icon(Icons.receipt),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DebtType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại nợ',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: DebtType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getDebtTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _principalController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền gốc (VND) *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số tiền';
                  if (double.tryParse(value!) == null) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Số dư hiện tại (VND) *',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số dư';
                  if (double.tryParse(value!) == null) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                decoration: const InputDecoration(
                  labelText: 'Lãi suất (%/năm) *',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập lãi suất';
                  final rate = double.tryParse(value!);
                  if (rate == null) return 'Số không hợp lệ';
                  if (rate < 0 || rate > 100) return 'Lãi suất phải từ 0-100%';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditorController,
                decoration: const InputDecoration(
                  labelText: 'Chủ nợ (tùy chọn)',
                  hintText: 'Ví dụ: Vietcombank, Techcombank',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngày bắt đầu: ${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Chưa chọn'}',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Chọn'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngày đáo hạn: ${_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Chưa chọn (tùy chọn)'}',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Chọn'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (date != null) {
                        setState(() => _dueDate = date);
                      }
                    },
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDebtTypeName(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Thẻ tín dụng';
      case DebtType.personalLoan:
        return 'Vay cá nhân';
      case DebtType.mortgage:
        return 'Vay mua nhà';
      case DebtType.other:
        return 'Khác';
    }
  }
}

