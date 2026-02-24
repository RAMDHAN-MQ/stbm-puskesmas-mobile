import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page.dart';
import '../config.dart';
import 'isi_beranda/isi_beranda.dart';
import 'isi_beranda/tambah_stbm.dart';
import 'profile/isi_profile.dart';
import 'riwayat/isi_riwayat.dart';
import 'statistik/isi_statistik.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _selectedIndex = 0;

  static const Color darkGreen = Color(0xFF198754);
  static const Color primaryGreen = Color(0xFF128C7E);

  // GANTI SESUAI IP LARAVEL
  static const String baseUrl = '${Config.baseUrl}';

  String nama = '';
  String nip = '';
  String foto = '';

  final List<Widget> _pages = const [
    IsiBeranda(), // 0 Dashboard
    StatistikPage(), // 1 Statistik
    RiwayatPage(), // 2 Riwayat
    IsiProfile(), // 3 Profile
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? '';
      nip = prefs.getString('nip') ?? '';
      foto = prefs.getString('foto') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryGreen : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? primaryGreen : Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: darkGreen,
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Center(
              child: SizedBox(
                height: 80,
                child: Row(
                  children: [
                    const SizedBox(width: 16),

                    // FOTO PROFIL
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage: foto.isNotEmpty
                          ? NetworkImage(
                              '$baseUrl/storage/profile/$foto',
                            )
                          : null,
                      child: foto.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),

                    const SizedBox(width: 14),

                    // NAMA & nip
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama.isNotEmpty ? nama : '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nip.isNotEmpty ? 'NIP: $nip' : 'nip: -',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LOGOUT
                    IconButton(
                      icon: const Icon(Icons.logout, size: 26),
                      color: Colors.white,
                      onPressed: _logout,
                    ),

                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahStbmPage()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Beranda", 0),
              _buildNavItem(Icons.bar_chart, "Statistik", 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.history, "Riwayat", 2),
              _buildNavItem(Icons.person, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }
}
