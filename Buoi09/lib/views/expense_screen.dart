import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/ui_helpers.dart';
import '../utils/validation.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _controller = ExpenseController();
  late Future<List<Expense>> _expenses;
  @override
  void initState() {
    super.initState();
    _expenses = _controller.fetchExpenses();
  }

  void _reload() {
    final expenses = _controller.fetchExpenses();
    setState(() {
      _expenses = expenses;
    });
  }

  Future<void> _edit([Expense? expense]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseDialog(expense: expense),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _delete(Expense expense) async {
    if (!await confirmDelete(context, expense.content) || !mounted) return;
    try {
      await _controller.delete(expense.id!);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý chi tiêu')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expenses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(errorMessage(snapshot.error!)));
          }
          final expenses = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tổng chi: ${expenses.fold<int>(0, (sum, e) => sum + e.amount)} đồng',
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('Chưa có khoản chi.'))
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return ListTile(
                            title: Text(expense.content),
                            subtitle: Text(
                              '${expense.amount} đồng\n${expense.note}',
                            ),
                            onTap: () => _edit(expense),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _delete(expense),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ExpenseDialog extends StatefulWidget {
  final Expense? expense;
  const ExpenseDialog({super.key, this.expense});
  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _content = TextEditingController(text: widget.expense?.content);
  late final _amount = TextEditingController(
    text: widget.expense?.amount.toString(),
  );
  late final _note = TextEditingController(text: widget.expense?.note);
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _content.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ExpenseController().save(
        Expense(
          id: widget.expense?.id,
          content: _content.text,
          amount: int.parse(_amount.text.trim()),
          note: _note.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.expense == null ? 'Thêm khoản chi' : 'Sửa khoản chi',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _content,
                  enabled: !_saving,
                  validator: requiredText,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền'),
                  validator: (value) {
                    final amount = int.tryParse(value?.trim() ?? '');
                    return amount == null ||
                            amount <= 0 ||
                            amount > 1000000000000
                        ? 'Số tiền phải là số nguyên dương, tối đa 1.000.000.000.000.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
