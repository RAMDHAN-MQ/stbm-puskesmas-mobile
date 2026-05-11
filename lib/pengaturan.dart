import 'package:flutter/material.dart';
import 'package:stbm_mobile/config.dart';

class Pengaturan extends StatefulWidget {
  const Pengaturan({super.key});

  @override
  State<Pengaturan> createState() => _PengaturanState();
}

class _PengaturanState extends State<Pengaturan> {
  final TextEditingController ipController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadIp();
  }

  Future<void> loadIp() async {
    final ip = await Config.getIp();

    ipController.text = ip;
  }

  Future<void> simpanIp() async {
    await Config.saveIp(ipController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("IP berhasil disimpan"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: "IP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: simpanIp,
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}
