import 'package:flutter/material.dart';

import '../controllers/student_controller.dart';
import '../models/sinh_vien.dart';
import '../utils/ui_helpers.dart';
import '../utils/validation.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final _controller = StudentController();
  final _search = TextEditingController();

  List<SinhVien> _students = [];
  bool _busy = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final requestId = ++_requestId;

    try {
      final students = await _controller.search(_search.text);

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _students = students;
        _error = null;
      });
    } catch (e) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = errorMessage(e));
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openForm([SinhVien? student]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => StudentDialog(student: student),
    );

    if (changed == true && mounted) {
      await _loadStudents();
    }
  }

  Future<void> _deleteStudent(SinhVien student) async {
    setState(() => _busy = true);

    try {
      final confirmed = await confirmDelete(context, student.name);

      if (!confirmed || !mounted) return;

      await _controller.delete(student.id!);
      await _loadStudents();
    } catch (e) {
      if (mounted) {
        showMessage(context, errorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sinh viên')),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xfff3efff), Color(0xffffe0ee)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _search,
                enabled: !_busy,
                onChanged: (_) => _loadStudents(),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sinh viên...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _busy
                        ? null
                        : () {
                            _search.clear();
                            _loadStudents();
                          },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _students.isEmpty
                    ? const Center(child: Text('Không có sinh viên.'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];

                          return Card(
                            color: Colors.blueGrey.shade100,
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.school),
                              ),
                              title: Text(student.name),
                              subtitle: Text(student.email),
                              onTap: () => _openForm(student),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteStudent(student),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentDialog extends StatefulWidget {
  final SinhVien? student;

  const StudentDialog({
    super.key,
    this.student,
  });

  @override
  State<StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<StudentDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(
    text: widget.student?.name,
  );

  late final _email = TextEditingController(
    text: widget.student?.email,
  );

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await StudentController().save(
        SinhVien(
          id: widget.student?.id,
          name: _name.text,
          email: _email.text,
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = errorMessage(e));
      }
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
          widget.student == null
              ? 'Thêm Sinh Viên'
              : 'Thông tin chi tiết sinh viên',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.student != null)
                  Text('ID: ${widget.student!.id}'),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  validator: requiredText,
                  decoration: const InputDecoration(
                    labelText: 'Tên Sinh Viên',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  enabled: !_saving,
                  validator: emailError,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
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
            child: Text(
              widget.student == null ? 'Lưu' : 'Cập nhật',
            ),
          ),
        ],
      ),
    );
  }
}