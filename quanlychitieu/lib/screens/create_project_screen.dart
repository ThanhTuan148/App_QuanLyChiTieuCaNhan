/// Màn hình tạo dự án mới trong nhóm
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/project.dart';
import '../models/group.dart';

class CreateProjectScreen extends StatefulWidget {
  final Group group;

  const CreateProjectScreen({super.key, required this.group});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Nếu endDate nhỏ hơn startDate, reset endDate
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final groupProvider = context.read<GroupProvider>();
    try {
      final project = await groupProvider.createProject(
        groupId: widget.group.id!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        budget: _budgetController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetController.text.trim()),
      );

      if (mounted) {
        Navigator.pop(context, project);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dự án đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Dự án'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tạo dự án mới trong nhóm "${widget.group.name}"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên dự án *',
                  hintText: 'Ví dụ: Dự án Marketing Q1',
                  prefixIcon: const Icon(Icons.folder),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên dự án';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  hintText: 'Mô tả về dự án',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => _selectDate(context, isStartDate: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Chọn ngày',
                          style: TextStyle(
                            color: _startDate != null
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => _selectDate(context, isStartDate: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày kết thúc',
                          prefixIcon: const Icon(Icons.event),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Chọn ngày',
                          style: TextStyle(
                            color: _endDate != null
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Ngân sách (tùy chọn)',
                  hintText: 'Ví dụ: 10000000',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final budget = double.tryParse(value.trim());
                    if (budget == null || budget < 0) {
                      return 'Vui lòng nhập số tiền hợp lệ';
                    }
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _createProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Tạo dự án',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Lưu ý',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Dự án sẽ được thêm vào nhóm hiện tại\n'
                        '• Bạn có thể thêm giao dịch vào dự án sau\n'
                        '• Ngân sách giúp theo dõi chi tiêu của dự án',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

