import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  File? bukti;
  final ImagePicker _picker = ImagePicker();

  int? pegawaiId;
  int? selectedWilayahId;

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        bukti = File(pickedFile.path);
      });
    }
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
      final baseUrl = await Config.baseUrl;
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
      final baseUrl = await Config.baseUrl;
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

    if (pegawaiId == null ||
        selectedKk == null ||
        namaKepalaKkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data wajib diisi')),
      );
      return;
    }

    if (bukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti wajib diambil')),
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
      final baseUrl = await Config.baseUrl;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/simpanSTBM'),
      );

      request.fields['pegawai_id'] = pegawaiId.toString();
      request.fields['wilayah_id'] = selectedWilayahId.toString();
      request.fields['no_kk'] = noKk!;
      request.fields['jawaban'] = jsonEncode(jawabanList);

      if (bukti != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'bukti',
            bukti!.path,
          ),
        );
      }

      final response = await request.send();

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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value.isEmpty ? '-' : value,
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
            if (selectedKk != null) ...[
              buildInfo('Wilayah', wilayah.text),
              buildInfo('Nama Kepala KK', namaKepalaKkController.text),
              buildInfo('RT', rtController.text),
              buildInfo('RW', rwController.text),
              buildInfo('Jumlah Jiwa', jumlahJiwaController.text),
              buildInfo(
                'Jumlah Jiwa Menetap',
                jumlahJiwaMenetapController.text,
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Bukti'),
                  ),
                  const SizedBox(width: 12),
                  if (bukti != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              if (bukti != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(
                    bukti!,
                    height: 150,
                  ),
                ),
            ],
            Divider(),
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
