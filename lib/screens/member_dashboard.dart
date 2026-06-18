import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _activeMembership;
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _attendances = [];
  bool _isLoadingAttendances = false;

  List<Map<String, dynamic>> _classes = [];
  Map<String, int> _classBookingCounts = {};
  Set<String> _userBookedClassIds = {};
  bool _isLoadingClasses = false;
  bool _classesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('memberships')
            .select('*, membership_plans(nama)')
            .eq('user_id', userId)
            .eq('status', 'aktif')
            .order('tanggal_berakhir', ascending: false)
            .limit(1),
        Supabase.instance.client
            .from('membership_plans')
            .select('id, nama, durasi_hari, harga')
            .order('harga'),
      ]);

      if (mounted) {
        final membershipList = results[0] as List;
        setState(() {
          _activeMembership = membershipList.isNotEmpty
              ? membershipList.first as Map<String, dynamic>
              : null;
          _plans = List<Map<String, dynamic>>.from(results[1] as List);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendances() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (mounted) setState(() => _isLoadingAttendances = true);
    try {
      final data = await Supabase.instance.client
          .from('attendances')
          .select('waktu_checkin')
          .eq('user_id', userId)
          .order('waktu_checkin', ascending: false);
      if (mounted) {
        setState(() {
          _attendances = List<Map<String, dynamic>>.from(data as List);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAttendances = false);
    }
  }

  Future<void> _loadClasses() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (mounted) setState(() => _isLoadingClasses = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('classes')
            .select('id, nama, jadwal, kuota')
            .order('jadwal'),
        Supabase.instance.client
            .from('class_bookings')
            .select('class_id, user_id'),
      ]);

      final classes = List<Map<String, dynamic>>.from(results[0] as List);
      final bookings = List<Map<String, dynamic>>.from(results[1] as List);

      final Map<String, int> counts = {};
      final Set<String> userBooked = {};
      for (final b in bookings) {
        final cid = b['class_id']?.toString() ?? '';
        counts[cid] = (counts[cid] ?? 0) + 1;
        if (b['user_id']?.toString() == userId) {
          userBooked.add(cid);
        }
      }

      if (mounted) {
        setState(() {
          _classes = classes;
          _classBookingCounts = counts;
          _userBookedClassIds = userBooked;
          _classesLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kelas: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _bookClass(String classId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('class_bookings')
          .insert({'class_id': classId, 'user_id': userId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil daftar kelas'), backgroundColor: Colors.green),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftar kelas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkIn() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('attendances')
          .insert({'user_id': userId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in berhasil'), backgroundColor: Colors.green),
        );
        _loadAttendances();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal check-in: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _buyPlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paket: ${plan['nama'] ?? '-'}'),
            const SizedBox(height: 4),
            Text('Harga: ${_formatRupiah(plan['harga'] ?? 0)}'),
            const SizedBox(height: 12),
            const Text(
              'Ini adalah pembayaran simulasi demo.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Beli'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final planId = plan['id']?.toString();
      final harga = (plan['harga'] as num?)?.toInt() ?? 0;
      final durasi = (plan['durasi_hari'] as num?)?.toInt() ?? 0;
      final now = DateTime.now();

      String _fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final tanggalMulai = _fmt(now);
      final tanggalBerakhir = _fmt(now.add(Duration(days: durasi)));

      await Supabase.instance.client
          .from('memberships')
          .update({'status': 'nonaktif'})
          .eq('user_id', userId)
          .eq('status', 'aktif');

      await Supabase.instance.client.from('memberships').insert({
        'user_id': userId,
        'plan_id': planId,
        'tanggal_mulai': tanggalMulai,
        'tanggal_berakhir': tanggalBerakhir,
        'status': 'aktif',
      });

      await Supabase.instance.client.from('payments').insert({
        'user_id': userId,
        'plan_id': planId,
        'jumlah': harga,
        'status': 'lunas',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil (demo), membership aktif'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = true;
        });
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal membeli paket: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  String _formatRupiah(num harga) {
    final str = harga.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(str[i]);
      count++;
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date $time';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Fit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildBerandaTab(),
          _buildKelasTab(),
          _buildAbsensiTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1 && !_classesLoaded && !_isLoadingClasses) {
            _loadClasses();
          }
          if (index == 2 && _attendances.isEmpty && !_isLoadingAttendances) {
            _loadAttendances();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Kelas'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Absensi'),
        ],
      ),
    );
  }

  Widget _buildBerandaTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMembershipStatusCard(),
          const SizedBox(height: 24),
          Text(
            'Paket Membership',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._plans.map(_buildPlanCard),
          if (_plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada paket tersedia', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildMembershipStatusCard() {
    final membership = _activeMembership;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Status Membership',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (membership == null)
              const Text('Belum punya membership aktif',
                  style: TextStyle(color: Colors.grey))
            else ...[
              _infoRow('Paket', membership['membership_plans']?['nama'] ?? '-'),
              const SizedBox(height: 8),
              _infoRow(
                  'Berlaku hingga',
                  _formatDate(membership['tanggal_berakhir']?.toString())),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.star_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['nama'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${plan['durasi_hari'] ?? '-'} hari',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    _formatRupiah(plan['harga'] ?? 0),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _buyPlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Beli Paket',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsensiTab() {
    return RefreshIndicator(
      onRefresh: _loadAttendances,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _checkIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                'Check-in Sekarang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Riwayat Kehadiran',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingAttendances)
            const Center(child: CircularProgressIndicator())
          else if (_attendances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada riwayat check-in',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._attendances.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                    ),
                    title: Text(
                      _formatDateTime(item['waktu_checkin']?.toString()),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildKelasTab() {
    if (_isLoadingClasses) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada kelas', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            )
          else
            ..._classes.map(_buildClassCard),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> cls) {
    final classId = cls['id']?.toString() ?? '';
    final kuota = (cls['kuota'] as num?)?.toInt() ?? 0;
    final terisi = _classBookingCounts[classId] ?? 0;
    final isBooked = _userBookedClassIds.contains(classId);
    final isFull = terisi >= kuota;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cls['nama'] ?? '-',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  cls['jadwal']?.toString() ?? '-',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Terisi $terisi / $kuota',
                  style: TextStyle(
                    color: isFull ? Colors.red : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!isBooked && !isFull) ? () => _bookClass(classId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isBooked ? Colors.grey.shade300 : Colors.red.shade100,
                  disabledForegroundColor: isBooked ? Colors.grey.shade600 : Colors.red.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isBooked ? 'Sudah Terdaftar' : isFull ? 'Penuh' : 'Daftar',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
