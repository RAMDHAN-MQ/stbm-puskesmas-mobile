import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsiBeranda extends StatefulWidget {
  const IsiBeranda({super.key});

  @override
  State<IsiBeranda> createState() => _IsiBerandaState();
}

class _IsiBerandaState extends State<IsiBeranda> {
  static const Color primaryGreen = Color(0xFF128C7E);

  int totalData = 0;
  int bulanIni = 0;
  int hariIni = 0;

  List desaList = [];
  List dataTerakhir = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await Config.baseUrl;
    final pegawaiId = prefs.getInt('pegawai_id');

    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard?pegawai_id=$pegawaiId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        totalData = data['total_data'];
        bulanIni = data['bulan_ini'];
        hariIni = data['hari_ini'];
        desaList = data['desa_list'];
        dataTerakhir = data['data_terakhir'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: fetchDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildCard("Total Data", totalData)),
                const SizedBox(width: 10),
                Expanded(child: _buildCard("Bulan Ini", bulanIni)),
                const SizedBox(width: 10),
                Expanded(child: _buildCard("Hari Ini", hariIni)),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              "Data per Desa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...desaList.map((desa) => Card(
                  child: ListTile(
                    title: Text(desa['desa']),
                    trailing: Text(
                      desa['total_input'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
            const SizedBox(height: 25),
            const Text(
              "Data Terakhir",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...dataTerakhir.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item['nama_kepala_kk']),
                  subtitle: Text("${item['desa']} • ${item['tanggal']}"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }
}
