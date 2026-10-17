import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

String errorMessage(Object error) {
  if (error is DatabaseException &&
      error.isUniqueConstraintError()) {
    return 'Tên công việc hoặc email đã tồn tại.';
  }

  if (error is ArgumentError) {
    return error.message?.toString() ?? 'Dữ liệu không hợp lệ.';
  }

  return 'Không thực hiện được thao tác: $error';
}

void showMessage(
  BuildContext context,
  String text, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}

Future<bool> confirmDelete(
  BuildContext context,
  String name,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có muốn xóa "$name"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Xóa'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}