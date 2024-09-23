import 'package:gpspro/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  static late SharedPreferences prefs;

  static String? getLanguage() {
    return prefs.getString(PREF_LANGUAGE);
  }

  static void setLanguage(String lang) {
    prefs.setString(PREF_LANGUAGE, lang);
  }

  static String? getEmail() {
    return prefs.getString(PREF_EMAIL);
  }

  static void setEmail(String email) {
    prefs.setString(PREF_EMAIL, email);
  }

  static String? getServerUrl() {
    return prefs.getString(PREF_URL);
  }

  static void setServerUrl(String url) {
    prefs.setString(PREF_URL, url);
  }

  static String? getPassword() {
    return prefs.getString(PREF_PASSWORD).toString();
  }

  static void setPassword(String password) {
    prefs.setString(PREF_PASSWORD, password);
  }

  // static UserLogin getUser() {
  //   return prefs.getString(PREF_USER);
  // }
  //
  // static void setUser(UserLogin user) {
  //   prefs.setString(PREF_PASSWORD, user);
  // }

  static void doLogout() {
    prefs.clear();
  }

}