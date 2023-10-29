import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsRepository {
  bool getBool(String name, {bool defaultValue = false});
  Future<void> setBool(String name, bool value);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  late SharedPreferences _prefs;

  SharedPreferencesSettingsRepository(SharedPreferences prefs) {
    _prefs = prefs;
  }

  @override
  bool getBool(String name, {bool defaultValue = false}) {
    var retrievedValue = _prefs.getBool(name);
    if (retrievedValue == null) {
      _prefs.setBool(name, defaultValue);
      return defaultValue;
    }
    return retrievedValue;
  }

  @override
  Future<void> setBool(String name, bool value) async {
    await _prefs.setBool(name, value);
  }
}

Future<SharedPreferencesSettingsRepository> repoFactory() async {
  var prefs = await SharedPreferences.getInstance();
  return SharedPreferencesSettingsRepository(prefs);
}
