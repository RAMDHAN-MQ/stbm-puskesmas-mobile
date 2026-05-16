import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stbm_mobile/config.dart';

class DetailStbmPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailStbmPage({super.key, required this.data});

  @override
  State<DetailStbmPage> createState() => _DetailStbmPageState();
}

class _DetailStbmPageState extends State<DetailStbmPage> {
  String baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final url = await Config.baseUrl;
    setState(() {
      baseUrl = url;
    });
  }

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

  String getBuktiUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '$baseUrl/storage/stbm/$path';
  }

  Widget buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value.isEmpty ? '-' : value,
            ),
          ],
        ),
      ),
    );
  }

  void showPilarDialog(BuildContext context, int pilar) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _PilarDialog(stbmId: widget.data['id'], pilar: pilar);
      },
    );
  }

  Widget buildPilarStatus(int number, String? value, BuildContext context) {
    return InkWell(
      onTap: () {
        showPilarDialog(context, number);
      },
      child: Container(
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
            Text("Pilar $number",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              formatStatus(value),
              style: TextStyle(
                color: getStatusColor(value),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfo("Nama Petugas", widget.data['pegawai']?['nama'] ?? "-"),
            buildInfo("Desa", widget.data['wilayah']?['desa'] ?? "-"),
            buildInfo("No KK", widget.data['kk']?['no_kk']?.toString() ?? "-"),
            buildInfo(
                "Nama Kepala KK", widget.data['kk']?['nama_kepala_kk'] ?? "-"),
            buildInfo("RT", widget.data['kk']?['rt']?.toString() ?? "-"),
            buildInfo("RW", widget.data['kk']?['rw']?.toString() ?? "-"),
            buildInfo("Jumlah Jiwa",
                widget.data['kk']?['jumlah_jiwa']?.toString() ?? "-"),
            buildInfo("Jumlah Jiwa Menetap",
                widget.data['kk']?['jumlah_jiwa_menetap']?.toString() ?? "-"),
            Text(
              "Bukti:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.data['bukti'] != null && baseUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  getBuktiUrl(widget.data['bukti']),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text("Gagal memuat gambar bukti");
                  },
                ),
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
            buildPilarStatus(1, widget.data['pilar_1'], context),
            buildPilarStatus(2, widget.data['pilar_2'], context),
            buildPilarStatus(3, widget.data['pilar_3'], context),
            buildPilarStatus(4, widget.data['pilar_4'], context),
            buildPilarStatus(5, widget.data['pilar_5'], context),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}

class _PilarDialog extends StatefulWidget {
  final int stbmId;
  final int pilar;

  const _PilarDialog({
    required this.stbmId,
    required this.pilar,
  });

  @override
  State<_PilarDialog> createState() => _PilarDialogState();
}

class _PilarDialogState extends State<_PilarDialog> {
  bool isJawabanBenar(int isNegatif, String jawaban) {
    if (isNegatif == 1) {
      return jawaban.toLowerCase() == "tidak";
    } else {
      return jawaban.toLowerCase() == "ya";
    }
  }

  Color getJawabanColor(int isNegatif, String jawaban) {
    return isJawabanBenar(isNegatif, jawaban) ? Colors.green : Colors.red;
  }

  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final baseUrl = await Config.baseUrl;
    final url =
        Uri.parse("$baseUrl/api/stbm/${widget.stbmId}/pilar/${widget.pilar}");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      setState(() {
        data = result['data'];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: double.infinity,
        child: Column(
          children: [
            Text(
              "Pilar ${widget.pilar}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];

                        final jawaban =
                            (item['stbm_details'] as List).isNotEmpty
                                ? item['stbm_details'][0]['jawaban']
                                : "-";

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: getJawabanColor(
                                  item['is_negatif'] ?? 0,
                                  jawaban,
                                ).withOpacity(0.5),
                              ),
                              color: getJawabanColor(
                                item['is_negatif'] ?? 0,
                                jawaban,
                              ).withOpacity(
                                  0.15), // transparan biar tidak terlalu mencolok
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(item['pertanyaan'] ?? "-"),
                              subtitle: Text("Jawaban: $jawaban"),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
