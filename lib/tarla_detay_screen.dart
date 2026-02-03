import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import 'florai_scanscreen.dart';

class TarlaDetayScreen extends StatefulWidget {
  final String tarlaId;
  const TarlaDetayScreen({super.key, required this.tarlaId});

  @override
  State<TarlaDetayScreen> createState() => _TarlaDetayScreenState();
}

class _TarlaDetayScreenState extends State<TarlaDetayScreen> {
  final Color background = const Color(0xFFFFF6E5);
  final Color accent = const Color(0xFFF4C37D);
  final DateFormat formatter = DateFormat('dd.MM.yyyy');

  DateTime? ekimTarihi;
  DateTime? sulamaTarihi;
  DateTime? ilaclamaTarihi;

  String? uid;
  List<Map<String, dynamic>> analizVerileri = [];
  final TextEditingController _notController = TextEditingController();
  List<Map<String, dynamic>> notlar = [];
  List<String> notDocIds = [];

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _loadTarihler();
    _loadAnalizVerileri();
    _loadNotlar();
  }

  Future<void> _loadTarihler() async {
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarlalar')
        .doc(widget.tarlaId)
        .get();

    final data = snapshot.data();
    if (data != null) {
      setState(() {
        ekimTarihi = (data['ekimTarihi'] as Timestamp?)?.toDate();
        sulamaTarihi = (data['sonSulamaTarihi'] as Timestamp?)?.toDate();
        ilaclamaTarihi = (data['sonIlaclamaTarihi'] as Timestamp?)?.toDate();
      });
    }
  }

  Future<void> _updateDateInFirestore(String type, DateTime? date) async {
    if (uid == null || date == null) return;
    String field = '';
    if (type == 'ekim') field = 'ekimTarihi';
    if (type == 'sulama') field = 'sonSulamaTarihi';
    if (type == 'ilaclama') field = 'sonIlaclamaTarihi';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarlalar')
        .doc(widget.tarlaId)
        .update({field: Timestamp.fromDate(date)});
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (type == 'ekim') ekimTarihi = pickedDate;
        if (type == 'sulama') sulamaTarihi = pickedDate;
        if (type == 'ilaclama') ilaclamaTarihi = pickedDate;
      });
      _updateDateInFirestore(type, pickedDate);
    }
  }

  Future<void> _loadAnalizVerileri() async {
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarlalar')
        .doc(widget.tarlaId)
        .collection('analizler')
        .orderBy('tarih', descending: false)
        .get();

    setState(() {
      analizVerileri = snapshot.docs.map((e) => e.data()).toList();
    });
  }

  Future<void> _loadNotlar() async {
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarlalar')
        .doc(widget.tarlaId)
        .collection('notlar')
        .orderBy('tarih', descending: true)
        .get();

    setState(() {
      notlar = snapshot.docs.map((e) => e.data()).toList();
      notDocIds = snapshot.docs.map((e) => e.id).toList();
    });
  }

  Future<void> _addNot() async {
    if (_notController.text.trim().isEmpty || uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarlalar')
        .doc(widget.tarlaId)
        .collection('notlar')
        .add({
      'icerik': _notController.text.trim(),
      'tarih': Timestamp.now(),
    });
    _notController.clear();
    _loadNotlar();
  }

  Future<void> _deleteNot(String docId) async {
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarlalar')
        .doc(widget.tarlaId)
        .collection('notlar')
        .doc(docId)
        .delete();
    _loadNotlar();
  }

  Widget _buildGrafik(List<FlSpot> spots, String baslik) {
    String xLabel = '';
    if (baslik.contains("Zaman Bazlı")) {
      xLabel = "X: Ölçüm Sırası";
    } else if (baslik.contains("Aylık")) {
      xLabel = "X: Son 30 Günlük Ölçümler";
    } else if (baslik.contains("Yıllık")) {
      xLabel = "X: Ay Numarası";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      height: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Y: Ayrık Otu Oranı (%)", style: TextStyle(fontSize: 12)),
              Text(xLabel, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 2,
                    color: Colors.red,
                    dotData: FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, _) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (spots.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, _) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }




  List<FlSpot> _getZamanBazliSpots() {
    return List.generate(analizVerileri.length, (i) {
      final oranStr = analizVerileri[i]['ayrik_otu'].toString().replaceAll('%', '');
      final oran = double.tryParse(oranStr) ?? 0;
      return FlSpot(i.toDouble(), oran);
    });
  }


  List<FlSpot> _getAylikSpots() {
    final now = DateTime.now();
    final recent = analizVerileri.where((e) {
      final tarih = (e['tarih'] as Timestamp).toDate();
      return now.difference(tarih).inDays <= 30;
    }).toList();

    return List.generate(recent.length, (i) {
      final oranStr = recent[i]['ayrik_otu'].toString().replaceAll('%', '');
      final oran = double.tryParse(oranStr) ?? 0;
      return FlSpot(i.toDouble(), oran);
    });
  }


  List<FlSpot> _getYillikSpots() {
    final Map<int, List<double>> aylikOranlar = {};
    for (var e in analizVerileri) {
      final tarih = (e['tarih'] as Timestamp).toDate();
      final oranStr = e['ayrik_otu'].toString().replaceAll('%', '');
      final oran = double.tryParse(oranStr) ?? 0;
      aylikOranlar.putIfAbsent(tarih.month, () => []).add(oran);
    }

    final spots = <FlSpot>[];
    for (var ay = 1; ay <= 12; ay++) {
      final oranlar = aylikOranlar[ay] ?? [];
      final ort = oranlar.isNotEmpty ? oranlar.reduce((a, b) => a + b) / oranlar.length : 0;
      spots.add(FlSpot(ay.toDouble(), ort.toDouble()));
    }
    return spots;
  }


  Widget _buildNotAlani() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text("Notlar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _notController,
          decoration: const InputDecoration(
            labelText: "Yeni Not",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF4C37D),
            foregroundColor: Colors.black,
          ),
          onPressed: _addNot,
          child: const Text("Kaydet"),
        ),
        const SizedBox(height: 8),
        ...List.generate(notlar.length, (index) {
          final not = notlar[index];
          final id = notDocIds[index];
          return ListTile(
            tileColor: Colors.orange.shade50,
            title: Text(not['icerik'] ?? ""),
            subtitle: Text(formatter.format((not['tarih'] as Timestamp).toDate())),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNot(id),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text("TARLAMIN DETAYLARI"),
        backgroundColor: accent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTarihTile("Ekim Tarihi", ekimTarihi, () => _selectDate(context, 'ekim')),
            _buildTarihTile("Son Sulama Tarihi", sulamaTarihi, () => _selectDate(context, 'sulama')),
            _buildTarihTile("Son İlaçlama Tarihi", ilaclamaTarihi, () => _selectDate(context, 'ilaclama')),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlorAIScanScreen(tarlaId: widget.tarlaId),
                    ),
                  ).then((_) => _loadAnalizVerileri());
                },
                icon: Image.asset('assets/florai_logo.png', width: 24),
                label: const Text("FlorAI"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Tarla Analizleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildGrafik(_getZamanBazliSpots(), "Zaman Bazlı Ayrık Otu Oranı (%)"),
            _buildGrafik(_getAylikSpots(), "Aylık Ayrık Otu Oranı (%)"),
            _buildGrafik(_getYillikSpots(), "Yıllık Ayrık Otu Oranı (%)"),
            _buildNotAlani(),
          ],
        ),
      ),
    );
  }

  Widget _buildTarihTile(String label, DateTime? date, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(label),
        subtitle: Text(date != null ? formatter.format(date) : "Henüz seçilmedi"),
        trailing: const Icon(Icons.calendar_month, size: 20),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

