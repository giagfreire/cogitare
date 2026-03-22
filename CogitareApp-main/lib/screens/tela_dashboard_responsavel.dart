static Future<void> saveResponsavelSession({
  required String token,
  required int responsavelId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
  await prefs.setInt('responsavel_id', responsavelId);
}

static Future<int?> getResponsavelId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('responsavel_id');
}