class Expense {
  final int? id;
  final String content;
  final int amount;
  final String note;

  const Expense({
    this.id,
    required this.content,
    required this.amount,
    this.note = '',
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'amount': amount,
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int,
      content: map['content'] as String,
      amount: map['amount'] as int,
      note: map['note'] as String,
    );
  }
}