import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarla_detay_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "";
  String userSurname = "";
  final TextEditingController _tarlaController = TextEditingController();
  final List<Map<String, dynamic>> _tarlalar = [];

  final Color background = const Color(0xFFFDF6E3);
  final Color accent = const Color(0xFFF4C37D);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTarlalar();
  }

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userName = userDoc['isim'] ?? '';
        userSurname = userDoc['soyisim'] ?? '';
      });
    }
  }

  Future<void> _fetchTarlalar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tarlalar')
          .get();
      setState(() {
        _tarlalar.clear();
        _tarlalar.addAll(snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}));
      });
    }
  }

  Future<void> _addTarla(String isim) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      print("\u274C UID bo\u015f, kullan\u0131c\u0131 giri\u015f yapmam\u0131\u015f olabilir.");
      return;
    }

    if (isim.trim().isEmpty) {
      print("\u26A0\uFE0F Tarla ad\u0131 bo\u015f.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L\u00fctfen bir tarla ad\u0131 girin.")),
      );
      return;
    }

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tarlalar')
          .add({
        'isim': isim,
        'eklenmeTarihi': FieldValue.serverTimestamp(),
        'konum': 'Bilinmiyor',
        'havaDurumu': 'Bilinmiyor',
        'ekimTarihi': FieldValue.serverTimestamp(),
        'sonSulamaTarihi': FieldValue.serverTimestamp(),
        'sonIlaclamaTarihi': FieldValue.serverTimestamp(),
      });

      print("\u2705 Firestore'a eklendi: \${docRef.id}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tarla ba\u015far\u0131yla eklendi.")),
      );

      _fetchTarlalar();
    } catch (e) {
      print("\u274C Tarla ekleme hatas\u0131: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata olu\u015ftu: $e")),
      );
    }
  }

  void _showTarlaEkleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Tarla Ekle"),
          content: TextField(
            controller: _tarlaController,
            decoration: const InputDecoration(hintText: "Tarla ad\u0131"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("\u0130ptal"),
            ),
            TextButton(
              onPressed: () {
                _addTarla(_tarlaController.text);
                _tarlaController.clear();
                Navigator.pop(context);
              },
              child: const Text("Ekle"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage("https://via.placeholder.com/150"),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "\ud83d\udc4b Ho\u015f geldin "),
                          TextSpan(
                            text: "$userName $userSurname",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: "!\nTarlalar\u0131n ne durumda, haydi birlikte g\u00f6zden ge\u00e7irelim.",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showTarlaEkleDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Tarla Ekle"),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _tarlalar.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final tarla = _tarlalar[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TarlaDetayScreen(
                            tarlaId: tarla['id'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              tarla['isim'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: PopupMenuButton<String>(
                              onSelected: (value) async {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) return;

                                if (value == 'rename') {
                                  final newNameController = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Tarla \u0130smini De\u011fi\u015ftir"),
                                      content: TextField(
                                        controller: newNameController,
                                        decoration: const InputDecoration(hintText: "Yeni isim"),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("\u0130ptal"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(uid)
                                                .collection('tarlalar')
                                                .doc(tarla['id'])
                                                .update({'isim': newNameController.text});
                                            Navigator.pop(context);
                                            _fetchTarlalar();
                                          },
                                          child: const Text("Kaydet"),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('tarlalar')
                                      .doc(tarla['id'])
                                      .delete();
                                  _fetchTarlalar();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('\u0130smi D\u00fczenle'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Sil'),
                                ),
                              ],
                              child: const Icon(Icons.more_vert, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
