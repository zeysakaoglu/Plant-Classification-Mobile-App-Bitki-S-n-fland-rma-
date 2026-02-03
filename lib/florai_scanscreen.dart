import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlorAIScanScreen extends StatefulWidget {
  final String tarlaId;
  const FlorAIScanScreen({super.key, required this.tarlaId});

  @override
  State<FlorAIScanScreen> createState() => _FlorAIScanScreenState();
}

class _FlorAIScanScreenState extends State<FlorAIScanScreen> {
  final Color background = const Color(0xFFFDF6E3);
  final Color accent = const Color(0xFFF4C37D);
  final List<Map<String, dynamic>> analizler = [];
  bool loading = false;

  final String apiUrl = "  https://2542-34-173-113-163.ngrok-free.app/predict";
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galeriden Ekle"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Fotoğraf Çek"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      File imageFile = File(picked.path);
      _analyzeWithFlorAI(imageFile);
    }
  }

  Future<void> _analyzeWithFlorAI(File imageFile) async {
    try {
      setState(() => loading = true);
      var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        final decoded = json.decode(result);
        final ayrik = decoded['ayrik_otu'];
        final saglikli = decoded['saglikli_bitki'];

        final now = DateTime.now();
        final data = {
          'zaman': now,
          'oran': ayrik,
          'saglikli': saglikli,
        };

        setState(() {
          analizler.add(data);
        });

        if (uid != null && widget.tarlaId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('tarlalar')
              .doc(widget.tarlaId)
              .collection('analizler')
              .add({
            'tarih': Timestamp.fromDate(now),
            'ayrik_otu': ayrik,
            'saglikli_bitki': saglikli
          });
        }
      } else {
        print("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Hata oluştu: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildChatBubble(Map<String, dynamic> analiz) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "🧠 FlorAI: Ayrık otu oranı ${analiz['oran']}, Sağlıklı: ${analiz['saglikli']}",
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text("FlorAI"),
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          if (loading)
            const LinearProgressIndicator(minHeight: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: analizler.length,
              itemBuilder: (context, index) => _buildChatBubble(analizler[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
            child: ElevatedButton.icon(
              onPressed: _showImageOptions,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("FlorAI ile Analiz Et"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


