import 'package:shared_preferences/shared_preferences.dart';

/// Service: thin wrapper over `shared_preferences`, so repositories and
/// controllers never touch the plugin directly.
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}
