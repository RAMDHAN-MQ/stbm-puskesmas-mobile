import 'package:shared_preferences/shared_preferences.dart';

class Config {

  static const String _ipKey = 'server_ip';

  // Default IP
  static const String defaultIp = '192.168.1.64';

  // Ambil base URL
  static Future<String> get baseUrl async {

    final prefs = await SharedPreferences.getInstance();

    final ip = prefs.getString(_ipKey) ?? defaultIp;

    return "http://$ip:8000";
  }

  // Simpan IP
  static Future<void> saveIp(String ip) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_ipKey, ip);
  }

  // Ambil IP saja
  static Future<String> getIp() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_ipKey) ?? defaultIp;
  }
}