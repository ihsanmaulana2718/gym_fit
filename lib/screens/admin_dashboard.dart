import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

  List<Map<String, dynamic>> _plans = [];
  bool _isLoadingPlans = true;

  List<Map<String, dynamic>> _classes = [];
  bool _isLoadingClasses = true;

  static const _roles = ['member', 'admin'];

  static const _roleColors = {
    'member': Colors.blue,
    'admin': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPlans();
    _loadClasses();
  }

  Future<void> _loadUsers() async {
    if (mounted) setState(() => _isLoadingUsers = true);
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, nama, email, role')
          .order('nama');
      if (mounted) {
        setState(() => _users = List<Map<String, dynamic>>.from(data as List));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadPlans() async {
    if (mounted) setState(() => _isLoadingPlans = true);
    try {
      final data = await Supabase.instance.client
          .from('membership_plans')
          .select('id, nama, durasi_hari, harga')
          .order('nama');
      if (mounted) {
        setState(() => _plans = List<Map<String, dynamic>>.from(data as List));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat paket: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPlans = false);
    }
  }

  Future<void> _loadClasses() async {
    if (mounted) setState(() => _isLoadingClasses = true);
    try {
      final data = await Supabase.instance.client
          .from('classes')
          .select('id, nama, jadwal, kuota')
          .order('nama');
      if (mounted) {
        setState(() => _classes = List<Map<String, dynamic>>.from(data as List));
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

  String _formatRupiah(dynamic value) {
    final number = (value as num?)?.toInt() ?? 0;
    final str = number.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  Future<void> _showPaketDialog({Map<String, dynamic>? plan}) async {
    final namaCtrl = TextEditingController(text: plan?['nama']?.toString() ?? '');
    final durasiCtrl = TextEditingController(text: plan?['durasi_hari']?.toString() ?? '');
    final hargaCtrl = TextEditingController(text: plan?['harga']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = plan != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Paket' : 'Tambah Paket'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Paket'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durasiCtrl,
                  decoration: const InputDecoration(labelText: 'Durasi (hari)', suffixText: 'hari'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Durasi tidak boleh kosong';
                    if (int.tryParse(v.trim()) == null) return 'Masukkan angka yang valid';
                    if (int.parse(v.trim()) <= 0) return 'Durasi harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hargaCtrl,
                  decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Harga tidak boleh kosong';
                    if (int.tryParse(v.trim()) == null) return 'Masukkan angka yang valid';
                    if (int.parse(v.trim()) < 0) return 'Harga tidak boleh negatif';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final payload = {
      'nama': namaCtrl.text.trim(),
      'durasi_hari': int.parse(durasiCtrl.text.trim()),
      'harga': int.parse(hargaCtrl.text.trim()),
    };

    try {
      if (isEdit) {
        await Supabase.instance.client
            .from('membership_plans')
            .update(payload)
            .eq('id', plan['id']);
      } else {
        await Supabase.instance.client.from('membership_plans').insert(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Paket berhasil diperbarui' : 'Paket berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan paket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePaket(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Paket'),
        content: Text('Hapus paket "${plan['nama']}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('membership_plans')
          .delete()
          .eq('id', plan['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paket berhasil dihapus'), backgroundColor: Colors.green),
        );
        _loadPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus paket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showKelasDialog({Map<String, dynamic>? kelas}) async {
    final namaCtrl = TextEditingController(text: kelas?['nama']?.toString() ?? '');
    final jadwalCtrl = TextEditingController(text: kelas?['jadwal']?.toString() ?? '');
    final kuotaCtrl = TextEditingController(text: kelas?['kuota']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = kelas != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Kelas' : 'Tambah Kelas'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kelas'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: jadwalCtrl,
                  decoration: const InputDecoration(labelText: 'Jadwal'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Jadwal tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: kuotaCtrl,
                  decoration: const InputDecoration(labelText: 'Kuota', suffixText: 'orang'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Kuota tidak boleh kosong';
                    if (int.tryParse(v.trim()) == null) return 'Masukkan angka yang valid';
                    if (int.parse(v.trim()) <= 0) return 'Kuota harus lebih dari 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final payload = {
      'nama': namaCtrl.text.trim(),
      'jadwal': jadwalCtrl.text.trim(),
      'kuota': int.parse(kuotaCtrl.text.trim()),
    };

    try {
      if (isEdit) {
        await Supabase.instance.client
            .from('classes')
            .update(payload)
            .eq('id', kelas['id']);
      } else {
        await Supabase.instance.client.from('classes').insert(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Kelas berhasil diperbarui' : 'Kelas berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kelas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteKelas(Map<String, dynamic> kelas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: Text('Hapus kelas "${kelas['nama']}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('classes')
          .delete()
          .eq('id', kelas['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelas berhasil dihapus'), backgroundColor: Colors.green),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus kelas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeRole(String userId, String currentRole) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Role'),
        children: _roles.map((role) {
          final color = _roleColors[role] ?? Colors.grey;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, role),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  role,
                  style: TextStyle(
                    fontWeight: role == currentRole ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (role == currentRole) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check, size: 16, color: Colors.grey),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected == null || selected == currentRole) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': selected})
          .eq('id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Gym Fit'),
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
          _buildMemberTab(),
          _buildPaketTab(),
          _buildKelasTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Member'),
          BottomNavigationBarItem(icon: Icon(Icons.card_membership_outlined), label: 'Paket'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: 'Kelas'),
        ],
      ),
    );
  }

  Widget _buildMemberTab() {
    if (_isLoadingUsers) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: _users.isEmpty
          ? const Center(child: Text('Belum ada data member', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) => _buildUserCard(_users[index]),
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? '-';
    final color = _roleColors[role] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                (user['nama']?.toString() ?? '?').isNotEmpty
                    ? (user['nama'] as String)[0].toUpperCase()
                    : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nama']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email']?.toString() ?? '-',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _changeRole(user['id']?.toString() ?? '', role),
              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
              child: const Text('Ubah Role'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaketTab() {
    if (_isLoadingPlans) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadPlans,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () => _showPaketDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Paket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _plans.isEmpty
                ? const Center(
                    child: Text('Belum ada paket', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.card_membership_outlined, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['nama']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan['durasi_hari']} hari  ·  ${_formatRupiah(plan['harga'])}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showPaketDialog(plan: plan),
              icon: const Icon(Icons.edit_outlined),
              color: Colors.orange,
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _deletePaket(plan),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasTab() {
    if (_isLoadingClasses) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () => _showKelasDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kelas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _classes.isEmpty
                ? const Center(
                    child: Text('Belum ada kelas', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) => _buildKelasCard(_classes[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelasCard(Map<String, dynamic> kelas) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center_outlined, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas['nama']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${kelas['jadwal']}  ·  Kuota: ${kelas['kuota']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showKelasDialog(kelas: kelas),
              icon: const Icon(Icons.edit_outlined),
              color: Colors.orange,
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _deleteKelas(kelas),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }
}
