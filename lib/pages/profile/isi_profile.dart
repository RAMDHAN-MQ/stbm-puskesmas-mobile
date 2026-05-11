import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class IsiProfile extends StatefulWidget {
  const IsiProfile({super.key});

  @override
  State<IsiProfile> createState() => _IsiProfileState();
}

class _IsiProfileState extends State<IsiProfile> {
  String nama = '';
  String nip = '';
  String foto = '';
  String role = '';

  String baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final url = await Config.baseUrl;
    setState(() {
      nama = prefs.getString('nama') ?? '';
      nip = prefs.getString('nip') ?? '';
      foto = prefs.getString('foto') ?? '';
      role = prefs.getString('role') ?? '';

      baseUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = '$baseUrl/storage/profile/$foto';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              // FOTO PROFILE
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      foto.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: foto.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 30),

              // CARD INFORMASI
              Card(
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    children: [
                      _profileItem(Icons.person_outline, 'Nama Lengkap', nama),
                      const Divider(height: 30),
                      _profileItem(Icons.badge_outlined, 'NIP', nip),
                      const Divider(height: 30),
                      _profileItem(Icons.badge_outlined, 'Jabatan', role),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
