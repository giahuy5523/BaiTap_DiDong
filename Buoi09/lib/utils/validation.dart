String? requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Không được để trống.';
  }

  return null;
}

String? emailError(String? value) {
  final email = value?.trim() ?? '';

  final pattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  if (!pattern.hasMatch(email)) {
    return 'Email không hợp lệ.';
  }

  return null;
}

String escapeLike(String text) {
  return text
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}