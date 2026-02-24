import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class TambahStbmPage extends StatefulWidget {
  const TambahStbmPage({super.key});

  @override
  State<TambahStbmPage> createState() => _TambahStbmPageState();
}

class _TambahStbmPageState extends State<TambahStbmPage> {
  final TextEditingController noKkController = TextEditingController();
  final TextEditingController namaKepalaKkController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  final TextEditingController jumlahJiwaController = TextEditingController();
  final TextEditingController pegawaiController = TextEditingController();
  final TextEditingController jumlahJiwaMenetapController =
      TextEditingController();

  String? selectedWilayah;
  List<Map<String, dynamic>> wilayahList = [];

  int? pegawaiId;

  final String baseUrl = Config.baseUrl;

  // Data pertanyaan
  Map<int, List<Map<String, dynamic>>> pertanyaanPerPilar = {};
  Map<int, Map<int, String>> jawabanPerPertanyaan = {};

  @override
  void initState() {
    super.initState();
    _loadPegawai();
    _fetchWilayah();
    _fetchPertanyaan();
  }

  Future<void> _loadPegawai() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      pegawaiId = prefs.getInt('user_id');
      pegawaiController.text = prefs.getString('nama') ?? '';
    });
  }

  Future<void> _fetchWilayah() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/wilayah'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          wilayahList = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetch wilayah: $e')),
      );
    }
  }

  Future<void> _fetchPertanyaan() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pertanyaan'));
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        Map<int, List<Map<String, dynamic>>> grouped = {};
        Map<int, Map<int, String>> initialJawaban = {};
        for (var q in data) {
          int pilar = q['pilar'];
          grouped.putIfAbsent(pilar, () => []).add(q);
          initialJawaban.putIfAbsent(pilar, () => {})[q['id']] = '';
        }
        setState(() {
          pertanyaanPerPilar = grouped;
          jawabanPerPertanyaan = initialJawaban;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetch pertanyaan: $e')),
      );
    }
  }

  Future<void> _addStbm() async {
    final noKk = noKkController.text;
    final namaKepalaKk = namaKepalaKkController.text;
    final rt = rtController.text;
    final rw = rwController.text;
    final jumlahJiwa = jumlahJiwaController.text;
    final jumlahJiwaMenetap = jumlahJiwaMenetapController.text;

    if (pegawaiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pegawai tidak ditemukan, silakan login ulang')),
      );
      return;
    }

    if (selectedWilayah == null || noKk.isEmpty || namaKepalaKk.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data wajib diisi')),
      );
      return;
    }

    List<Map<String, dynamic>> jawabanList = [];
    jawabanPerPertanyaan.forEach((pilar, qMap) {
      qMap.forEach((qId, jawaban) {
        jawabanList.add({
          'pilar': pilar,
          'pertanyaan_id': qId,
          'jawaban': jawaban,
        });
      });
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/simpanSTBM'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pegawai_id': pegawaiId,
          'wilayah_id': selectedWilayah,
          'no_kk': noKk,
          'nama_kepala_kk': namaKepalaKk,
          'rt': rt,
          'rw': rw,
          'jumlah_jiwa': jumlahJiwa,
          'jumlah_jiwa_menetap': jumlahJiwaMenetap,
          'jawaban': jawabanList,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('STBM berhasil ditambahkan')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambah STBM')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showPertanyaanPilarModal(
      int pilar, List<Map<String, dynamic>> questions) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilar $pilar',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        final qId = q['id'];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${index + 1}. ${q['pertanyaan']}'),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Ya'),
                                    value: 'Ya',
                                    groupValue:
                                        jawabanPerPertanyaan[pilar]![qId],
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        jawabanPerPertanyaan[pilar]![qId] =
                                            val!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Tidak'),
                                    value: 'Tidak',
                                    groupValue:
                                        jawabanPerPertanyaan[pilar]![qId],
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        jawabanPerPertanyaan[pilar]![qId] =
                                            val!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ),
                  _isPilarComplete(pilar, questions)
                      ? ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Selesai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: null,
                          child: const Text('Jawab semua pertanyaan'),
                        ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  bool _isPilarComplete(int pilar, List<Map<String, dynamic>> questions) {
    for (var q in questions) {
      final qId = q['id'];
      if ((jawabanPerPertanyaan[pilar]?[qId] ?? '').isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah STBM'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF198754),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: pegawaiController,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedWilayah,
              decoration: const InputDecoration(labelText: 'Wilayah'),
              items: wilayahList.map((w) {
                return DropdownMenuItem(
                  value: w['id'].toString(),
                  child: Text(w['desa']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedWilayah = val;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noKkController,
              decoration: const InputDecoration(labelText: 'No. KK'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: namaKepalaKkController,
              decoration: const InputDecoration(labelText: 'Nama Kepala KK'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rtController,
              decoration: const InputDecoration(labelText: 'RT'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rwController,
              decoration: const InputDecoration(labelText: 'RW'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jumlahJiwaController,
              decoration: const InputDecoration(labelText: 'Jumlah Jiwa'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jumlahJiwaMenetapController,
              decoration:
                  const InputDecoration(labelText: 'Jumlah Jiwa Menetap'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ...pertanyaanPerPilar.entries.map((entry) {
              int pilar = entry.key;
              List<Map<String, dynamic>> questions = entry.value;

              bool isComplete = _isPilarComplete(pilar, questions);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: isComplete ? Colors.green[50] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isComplete ? Colors.green : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Pilar $pilar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${questions.length} pertanyaan'),
                  trailing: Icon(
                    isComplete ? Icons.check_circle : Icons.open_in_new,
                    color: isComplete ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    _showPertanyaanPilarModal(pilar, questions);
                  },
                ),
              );
            }).toList(),
            ElevatedButton(
              onPressed: _addStbm,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
