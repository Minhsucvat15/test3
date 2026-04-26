String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
  final r = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-\.]+$');
  if (!r.hasMatch(v.trim())) return 'Email không hợp lệ';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
  if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
  return null;
}

String? validateNotEmpty(String? v, {String label = 'Trường này'}) {
  if (v == null || v.trim().isEmpty) return '$label không được để trống';
  return null;
}
