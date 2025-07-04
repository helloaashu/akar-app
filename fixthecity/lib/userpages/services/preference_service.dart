import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static Future<bool> shouldShowAIModePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_ai_mode_prompt') ?? true;
  }

  static Future<void> setShowAIModePrompt(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_ai_mode_prompt', value);
  }
}
