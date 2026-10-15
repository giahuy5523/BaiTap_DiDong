import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatTime(DateTime time) => DateFormat('dd/MM/yyyy HH:mm').format(time);
void message(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text), backgroundColor: error ? Colors.red : Colors.green,
  ));
}

Future<DateTime?> pickDateTime(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  final start = initial != null && initial.isAfter(now) ? initial : now;
  final date = await showDatePicker(context: context, initialDate: start,
      firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(2100));
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context,
      initialTime: TimeOfDay.fromDateTime(start));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Widget scoreRow(int correct, int wrong) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    Chip(backgroundColor: Colors.green.shade100, label: Text('Đúng: $correct')),
    Chip(backgroundColor: Colors.orange.shade100, label: Text('Sai: $wrong')),
  ],
);
String normalize(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
