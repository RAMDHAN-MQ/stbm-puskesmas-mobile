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
  int currentPage = 1;
  int lastPage = 1;

  String? selectedDesa;

  List desaList = [];
  List<dynamic> stbmList = [];

  TextEditingController searchController = TextEditingController();

  bool isLoading = false;

  List<dynamic> get stbmProses =>
      stbmList.where((e) => e['status'] == 'proses').toList();

  List<dynamic> get stbmSelesai =>
      stbmList.where((e) => e['status'] == 'selesai').toList();

  @override
  void initState() {
    super.initState();
    _fetchStbm(reset: true);
    fetchDesa();
  }

  Future<void> fetchDesa() async {
    final prefs = await SharedPreferences.getInstance();
    final pegawaiId = prefs.getInt('pegawai_id');
    final baseUrl = await Config.baseUrl;

    final response = await http.get(
      Uri.parse('$baseUrl/api/stbm/listdesa?pegawai_id=$pegawaiId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        desaList = jsonDecode(response.body);
      });
    }
  }

  Future<void> _fetchStbm({bool reset = false}) async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final pegawaiId = prefs.getInt('pegawai_id');
    final baseUrl = await Config.baseUrl;

    if (reset) {
      currentPage = 1;
    }

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/stbm'
        '?pegawai_id=$pegawaiId'
        '&page=$currentPage'
        '&desa=${selectedDesa ?? ''}'
        '&search=${searchController.text}',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        stbmList = data['data'];
        lastPage = data['last_page'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void onSearchChanged(String value) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (value == searchController.text) {
        _fetchStbm(reset: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchStbm(reset: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari Nama / No KK',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedDesa,
                    hint: const Text("Semua Desa"),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("Semua Desa"),
                      ),
                      ...desaList.map<DropdownMenuItem<String>>((desa) {
                        return DropdownMenuItem(
                          value: desa['desa'],
                          child: Text(desa['desa']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDesa = value;
                      });
                      _fetchStbm(reset: true);
                    },
                  ),
                  const SizedBox(height: 10),
                  if (stbmList.isEmpty && !isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Data tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (stbmProses.isNotEmpty) ...[
                      statusHeader('Status Proses', Colors.orange),
                      stbmListView(stbmProses),
                    ],
                    if (stbmSelesai.isNotEmpty) ...[
                      statusHeader('Status Selesai', Colors.green),
                      stbmListView(stbmSelesai),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: currentPage > 1
                              ? () {
                                  setState(() => currentPage--);
                                  _fetchStbm();
                                }
                              : null,
                          child: const Text("<-"),
                        ),
                        Text("Halaman $currentPage / $lastPage"),
                        ElevatedButton(
                          onPressed: currentPage < lastPage
                              ? () {
                                  setState(() => currentPage++);
                                  _fetchStbm();
                                }
                              : null,
                          child: const Text("->"),
                        ),
                      ],
                    ),
                  ],
                ],
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
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
                ),
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
