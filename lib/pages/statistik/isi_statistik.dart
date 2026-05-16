import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  String? selectedTahun;
  List tahunList = [];
  bool isLoading = true;

  List perDesa = [];
  Map<String, dynamic> pilar = {};

  static const Color primaryGreen = Color(0xFF128C7E);

  @override
  void initState() {
    super.initState();
    fetchStatistik();
  }

  Future<void> fetchStatistik() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await Config.baseUrl;
    final pegawaiId = prefs.getInt('pegawai_id');

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/statistik?pegawai_id=$pegawaiId&tahun=${selectedTahun ?? ""}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        tahunList = data['tahun_list'] ?? [];
        perDesa = data['per_desa'] ?? [];
        pilar = data['pilar'] ?? {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Statistik",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedTahun,
                hint: const Text("Pilih Tahun"),
                items: tahunList.map<DropdownMenuItem<String>>((tahun) {
                  return DropdownMenuItem<String>(
                    value: tahun.toString(),
                    child: Text(tahun.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTahun = value;
                    isLoading = true;
                  });
                  fetchStatistik();
                },
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            "Data per Desa",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(perDesa.length, (index) {
                  final item = perDesa[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (item['total'] as num).toDouble(),
                        width: 18,
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < perDesa.length) {
                          return Text(
                            perDesa[index]['desa'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Data per Pilar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(5, (index) {
                  final key = "${index + 1}";
                  final layak = (pilar[key]?['layak'] ?? 0).toDouble();
                  final tidakLayak =
                      (pilar[key]?['tidak_layak'] ?? 0).toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: layak,
                        width: 10,
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: tidakLayak,
                        width: 10,
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "P${value.toInt() + 1}",
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.square, color: Colors.green, size: 14),
              SizedBox(width: 6),
              Text("Layak"),
              SizedBox(width: 20),
              Icon(Icons.square, color: Colors.red, size: 14),
              SizedBox(width: 6),
              Text("Tidak Layak"),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
