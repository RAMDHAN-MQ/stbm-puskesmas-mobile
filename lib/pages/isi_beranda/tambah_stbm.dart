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
  final TextEditingController wilayah = TextEditingController();
  final TextEditingController namaKepalaKkController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  final TextEditingController jumlahJiwaController = TextEditingController();
  final TextEditingController pegawaiController = TextEditingController();
  final TextEditingController jumlahJiwaMenetapController =
      TextEditingController();

  String? selectedKk;
  List<Map<String, dynamic>> kkList = [];

  int? pegawaiId;
  int? selectedWilayahId;

  final String baseUrl = Config.baseUrl;

  // Data pertanyaan
  Map<int, List<Map<String, dynamic>>> pertanyaanPerPilar = {};
  Map<int, Map<int, String>> jawabanPerPertanyaan = {};

  @override
  void initState() {
    super.initState();
    _loadPegawai();
    _fetchKk();
    _fetchPertanyaan();
  }

  Future<void> _loadPegawai() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      pegawaiId = prefs.getInt('pegawai_id');
      pegawaiController.text = prefs.getString('nama') ?? '';
    });
  }

  Future<void> _fetchKk() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/kk'));
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          kkList = data;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetch kk: $e')),
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
    final noKk = selectedKk;
    final namaKepalaKk = namaKepalaKkController.text;

    if (pegawaiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pegawai tidak ditemukan, silakan login ulang')),
      );
      return;
    }

    if (selectedKk == null || noKk!.isEmpty || namaKepalaKk.isEmpty) {
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
          'wilayah_id': selectedWilayahId,
          'no_kk': noKk,
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
            const SizedBox(height: 16),
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return kkList;
                }
                return kkList.where((kk) =>
                    kk['no_kk'].toString().contains(textEditingValue.text));
              },
              displayStringForOption: (option) => option['no_kk'].toString(),
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Pilih No KK',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              onSelected: (selection) {
                setState(() {
                  selectedKk = selection['no_kk'].toString();
                  selectedWilayahId = selection['wilayah_id'];

                  wilayah.text = selection['wilayah']?['desa'] ?? '';
                  namaKepalaKkController.text =
                      selection['nama_kepala_kk'] ?? '';
                  rtController.text = selection['rt'].toString();
                  rwController.text = selection['rw'].toString();
                  jumlahJiwaController.text =
                      selection['jumlah_jiwa'].toString();
                  jumlahJiwaMenetapController.text =
                      selection['jumlah_jiwa_menetap'].toString();
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: wilayah,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Wilayah',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: namaKepalaKkController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nama Kepala KK',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rtController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'RT',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rwController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'RW',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jumlahJiwaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah Jiwa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jumlahJiwaMenetapController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah Jiwa Menetap',
                border: OutlineInputBorder(),
              ),
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
