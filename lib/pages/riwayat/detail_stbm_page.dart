import 'package:flutter/material.dart';

class DetailStbmPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailStbmPage({super.key, required this.data});

  Color getStatusColor(String? value) {
    if (value == 'layak') return Colors.green;
    if (value == 'tidak_layak') return Colors.red;
    return Colors.grey;
  }

  String formatStatus(String? value) {
    if (value == 'layak') return "Layak";
    if (value == 'tidak_layak') return "Tidak Layak";
    return "-";
  }

  Widget buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildPilarStatus(int number, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: getStatusColor(value).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: getStatusColor(value)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Pilar $number",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            formatStatus(value),
            style: TextStyle(
              color: getStatusColor(value),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail STBM"),
        backgroundColor: const Color(0xFF198754),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildInfoTile("Nama Petugas", data['pegawai']?['nama'] ?? "-"),
            buildInfoTile("Desa", data['wilayah']?['desa'] ?? "-"),
            buildInfoTile(
              "No KK",
              data['no_kk']?.toString() ?? "-",
            ),
            buildInfoTile(
              "Nama Kepala KK",
              data['kk']?['nama_kepala_kk'] ?? "-",
            ),
            buildInfoTile(
              "RT",
              data['kk']?['rt']?.toString() ?? "-",
            ),
            buildInfoTile(
              "RW",
              data['kk']?['rw']?.toString() ?? "-",
            ),
            buildInfoTile(
              "Jumlah Jiwa",
              data['kk']?['jumlah_jiwa']?.toString() ?? "-",
            ),
            buildInfoTile(
              "Jumlah Jiwa Menetap",
              data['kk']?['jumlah_jiwa_menetap']?.toString() ?? "-",
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Status Pilar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildPilarStatus(1, data['pilar_1']),
            buildPilarStatus(2, data['pilar_2']),
            buildPilarStatus(3, data['pilar_3']),
            buildPilarStatus(4, data['pilar_4']),
            buildPilarStatus(5, data['pilar_5']),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}
