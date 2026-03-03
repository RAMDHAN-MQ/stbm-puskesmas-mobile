import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'detail_stbm_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> stbmList = [];
  final TextEditingController wilayahController = TextEditingController();
  final TextEditingController statusController = TextEditingController();

  final String baseUrl = Config.baseUrl;

  List<dynamic> get stbmProses =>
      stbmList.where((e) => e['status'] == 'proses').toList();

  List<dynamic> get stbmSelesai =>
      stbmList.where((e) => e['status'] == 'selesai').toList();

  @override
  void initState() {
    super.initState();
    _fetchStbm();
  }

  Future<void> _fetchStbm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pegawaiId = prefs.getInt('pegawai_id');
      final response = await http.get(Uri.parse('$baseUrl/api/stbm?pegawai_id=$pegawaiId'));
      if (response.statusCode == 200) {
        setState(() {
          stbmList = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data STBM')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Konten utama
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStbm,
              child: stbmList.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Text(
                              'Tidak ada data',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // STATUS PROSES
                          if (stbmProses.isNotEmpty) ...[
                            statusHeader('Status Proses', Colors.orange),
                            stbmListView(stbmProses),
                          ],

                          // STATUS SELESAI
                          if (stbmSelesai.isNotEmpty) ...[
                            statusHeader('Status Selesai', Colors.green),
                            stbmListView(stbmSelesai),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statusHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8, top: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), // warna tipis
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget stbmListView(List<dynamic> list) {
    return Column(
      children: list.map((stbm) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(stbm['wilayah']?['desa'] ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kepala Keluarga: ${stbm['kk']?['nama_kepala_kk'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'No KK: ${stbm['kk']?['no_kk'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailStbmPage(data: stbm),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
