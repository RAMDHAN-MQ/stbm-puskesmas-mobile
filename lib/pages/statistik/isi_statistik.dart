import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class StatistikWidget extends StatefulWidget {
  const StatistikWidget({super.key});

  @override
  State<StatistikWidget> createState() => _StatistikWidgetState();
}

class _StatistikWidgetState extends State<StatistikWidget> {
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
    final baseUrl = await Config.baseUrl;

    final response = await http.get(
      Uri.parse('$baseUrl/api/statistik'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        perDesa = data['per_desa'] ?? [];
        pilar = data['pilar'] ?? {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistik per Desa",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              maxY: perDesa.isEmpty
                  ? 10
                  : perDesa
                          .map((e) => (e['total'] as num).toDouble())
                          .reduce((a, b) => a > b ? a : b) +
                      3,
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
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < perDesa.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Transform.rotate(
                            angle: 0.5,
                            child: Text(
                              perDesa[index]['desa'],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      }

                      return const Text('');
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (
                    group,
                    groupIndex,
                    rod,
                    rodIndex,
                  ) {
                    return BarTooltipItem(
                      rod.toY.toString(),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          "Statistik per Pilar",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(5, (index) {
                final key = "${index + 1}";

                final layak =
                    (pilar[key]?['layak'] ?? 0).toDouble();

                final tidakLayak =
                    (pilar[key]?['tidak_layak'] ?? 0)
                        .toDouble();

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: layak,
                      width: 16,
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: tidakLayak,
                      width: 16,
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
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
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (
                    group,
                    groupIndex,
                    rod,
                    rodIndex,
                  ) {
                    return BarTooltipItem(
                      rod.toY.toString(),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
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
    );
  }
}