import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    return email == 'bryan456@gmail.com';
  }

  String _formatImageUrl(String rawUrl) {
    final clean = rawUrl.trim();
    if (clean.isEmpty) return '';
    if (clean.contains('wsrv.nl') || clean.startsWith('data:')) return clean;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(clean)}';
    }
    return clean;
  }

  void _showEditProfileDialog({
    required String uid,
    required String currentName,
    required String currentClass,
    required String currentPhoto,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentName);
    final classController = TextEditingController(text: currentClass);
    final photoController = TextEditingController(text: currentPhoto);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                isAdmin ? 'Edit Profil Admin' : 'Edit Profil Siswa',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkBlue,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: classController,
                          decoration: InputDecoration(
                            labelText: isAdmin ? 'Jabatan / Role *' : 'Kelas *',
                            hintText: isAdmin
                                ? 'Contoh: Admin Laboratorium'
                                : 'Contoh: XI RPL 7',
                            prefixIcon: const Icon(Icons.school_outlined),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Bagian ini wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: photoController,
                          decoration: const InputDecoration(
                            labelText: 'URL Foto Profil (Opsional)',
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);

                          try {
                            final formattedPhoto =
                                _formatImageUrl(photoController.text);

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                              'name': nameController.text.trim(),
                              'kelas': classController.text.trim(),
                              'photo_url': formattedPhoto,
                            }, SetOptions(merge: true));

                            await FirebaseAuth.instance.currentUser
                                ?.updateDisplayName(nameController.text.trim());

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil berhasil diperbarui!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui profil: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(isSaving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Akun',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDarkBlue,
          ),
        ),
        content: const Text('Apakah kamu yakin ingin logout dari iAlatLab?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil & Riwayat'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU HEADER PROFIL
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final String name = (data['name'] ?? user.displayName ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty
                    ? (data['name'] ?? user.displayName).toString().trim()
                    : (user.email?.split('@').first ?? 'Pengguna');
                final String email = user.email ?? '-';
                final String kelas = (data['kelas'] ??
                        data['class'] ??
                        (isAdmin ? 'Admin Laboratorium' : 'Siswa Lab'))
                    .toString()
                    .trim();
                final String photoUrl =
                    (data['photo_url'] ?? data['image'] ?? '').toString().trim();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryDarkBlue,
                        AppTheme.secondaryLightBlue,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDarkBlue.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDarkBlue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    kelas,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditProfileDialog(
                            uid: user.uid,
                            currentName: name,
                            currentClass: kelas,
                            currentPhoto: photoUrl,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text(
                            'Edit Profil',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. MENU TOMBOL RIWAYAT PEMINJAMAN (BERBEDA UNTUK ADMIN VS SISWA)
            Text(
              isAdmin ? 'Laporan & Riwayat Lab' : 'Aktivitas Peminjaman',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDarkBlue,
              ),
            ),
            const SizedBox(height: 10),

            if (isAdmin)
              // KARTU MENU UNTUK ADMIN (MELIHAT SEMUA RIWAYAT PEMINJAMAN SISWA)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('borrowings')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final int totalSemua = docs.length;
                  final int sedangDipinjam = docs.where((d) {
                    final m = d.data() as Map<String, dynamic>;
                    return m['status'] == 'Borrowed';
                  }).length;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminRiwayatPeminjamanScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.accentSkyBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.history_edu_rounded,
                                color: AppTheme.primaryDarkBlue,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Riwayat Peminjaman Alat (Semua User)',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDarkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalSemua == 0
                                        ? 'Belum ada riwayat peminjaman di lab'
                                        : 'Total $totalSemua transaksi • $sedangDipinjam sedang dipinjam',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppTheme.primaryDarkBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              // KARTU MENU UNTUK USER / SISWA
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('borrowings')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final int totalTransaksi = docs.length;
                  final int sedangDipinjam = docs.where((d) {
                    final m = d.data() as Map<String, dynamic>;
                    return m['status'] == 'Borrowed';
                  }).length;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RiwayatPeminjamanScreen(userId: user.uid),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.accentSkyBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: AppTheme.primaryDarkBlue,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Riwayat Peminjaman Alat',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDarkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalTransaksi == 0
                                        ? 'Belum ada riwayat peminjaman'
                                        : 'Total $totalTransaksi kali peminjaman${sedangDipinjam > 0 ? ' • $sedangDipinjam aktif' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppTheme.primaryDarkBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// HALAMAN RIWAYAT PEMINJAMAN KHUSUS ADMIN (SEMUA USER, LENGKAP DENGAN NAMA,
// KEPERLUAN, WAKTU PINJAM & WAKTU KEMBALI)
// ===========================================================================
class AdminRiwayatPeminjamanScreen extends StatefulWidget {
  const AdminRiwayatPeminjamanScreen({super.key});

  @override
  State<AdminRiwayatPeminjamanScreen> createState() =>
      _AdminRiwayatPeminjamanScreenState();
}

class _AdminRiwayatPeminjamanScreenState
    extends State<AdminRiwayatPeminjamanScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Sedang Dipinjam', 'Selesai'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is! Timestamp) return '-';
    final dt = ts.toDate();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy • $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Peminjaman Lab'),
      ),
      body: Column(
        children: [
          // Kolom Cari (Nama Alat / Nama Peminjam / Keperluan)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama alat, peminjam, atau keperluan...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryDarkBlue,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filter Chip: Semua, Sedang Dipinjam, Selesai
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: ['Semua', 'Sedang Dipinjam', 'Selesai'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryDarkBlue,
                    backgroundColor: AppTheme.accentSkyBlue,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : AppTheme.primaryDarkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),

          // Daftar Seluruh Riwayat Peminjaman dari Semua Siswa
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('borrowings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Gagal memuat riwayat: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Urutkan dari peminjaman terbaru di sisi client (tanpa perlu composite index Firestore)
                final sortedDocs = List<QueryDocumentSnapshot>.from(allDocs)
                  ..sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTs = aData['borrow_date'];
                    final bTs = bData['borrow_date'];
                    if (aTs is Timestamp && bTs is Timestamp) {
                      return bTs.compareTo(aTs);
                    }
                    return 0;
                  });

                // Filter status & kata kunci pencarian
                final filteredDocs = sortedDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString();

                  if (_selectedFilter == 'Sedang Dipinjam' &&
                      status != 'Borrowed') {
                    return false;
                  }
                  if (_selectedFilter == 'Selesai' && status != 'Returned') {
                    return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final itemName =
                        (data['item_name'] ?? '').toString().toLowerCase();
                    final borrowerName =
                        (data['borrower_name'] ?? '').toString().toLowerCase();
                    final purpose =
                        (data['purpose'] ?? '').toString().toLowerCase();
                    final code = (data['code'] ?? '').toString().toLowerCase();

                    return itemName.contains(_searchQuery) ||
                        borrowerName.contains(_searchQuery) ||
                        purpose.contains(_searchQuery) ||
                        code.contains(_searchQuery);
                  }

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ada riwayat peminjaman yang sesuai.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isBorrowed = data['status'] == 'Borrowed';
                    final String borrowerName =
                        (data['borrower_name'] ?? '').toString().trim();
                    final String purpose =
                        (data['purpose'] ?? '').toString().trim();

                    // Ambil userId dari path dokumen: users/{userId}/borrowings/{borrowId}
                    final String parentUserId =
                        doc.reference.parent.parent?.id ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baris Atas: Nama Barang, Kode & Badge Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['item_name'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDarkBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Kode: ${data['code'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isBorrowed
                                        ? Colors.orange.withOpacity(0.15)
                                        : Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isBorrowed
                                        ? 'Sedang Dipinjam'
                                        : 'Selesai Dipinjam',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isBorrowed
                                          ? Colors.orange[800]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Nama Peminjam (fallback otomatis ke koleksi users jika data lama belum punya borrower_name)
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppTheme.primaryDarkBlue,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Peminjam: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: borrowerName.isNotEmpty
                                      ? Text(
                                          borrowerName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryDarkBlue,
                                          ),
                                        )
                                      : FutureBuilder<DocumentSnapshot>(
                                          future: parentUserId.isNotEmpty
                                              ? FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(parentUserId)
                                                  .get()
                                              : null,
                                          builder: (context, userSnap) {
                                            final uData = userSnap.data?.data()
                                                as Map<String, dynamic>?;
                                            final resolvedName =
                                                (uData?['name'] ?? 'Siswa')
                                                    .toString();
                                            return Text(
                                              resolvedName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryDarkBlue,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Keperluan / Alasan Meminjam
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 16,
                                  color: AppTheme.secondaryLightBlue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Keperluan: ${purpose.isNotEmpty ? purpose : '-'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Dari Kapan (Waktu Pinjam)
                            Row(
                              children: [
                                const Icon(
                                  Icons.login_rounded,
                                  size: 15,
                                  color: AppTheme.secondaryLightBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pinjam: ${_formatTimestamp(data['borrow_date'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),

                            // Hingga Kapan (Waktu Kembali)
                            Row(
                              children: [
                                Icon(
                                  isBorrowed
                                      ? Icons.schedule
                                      : Icons.check_circle_outline,
                                  size: 15,
                                  color: isBorrowed
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBorrowed
                                      ? 'Kembali: Belum dikembalikan'
                                      : 'Kembali: ${_formatTimestamp(data['return_date'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// HALAMAN RIWAYAT PEMINJAMAN USER / SISWA (DIKELOMPOKKAN & HITUNG BERAPA KALI PINJAM)
// ===========================================================================
class RiwayatPeminjamanScreen extends StatefulWidget {
  final String userId;

  const RiwayatPeminjamanScreen({super.key, required this.userId});

  @override
  State<RiwayatPeminjamanScreen> createState() =>
      _RiwayatPeminjamanScreenState();
}

class _RiwayatPeminjamanScreenState extends State<RiwayatPeminjamanScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Sedang Dipinjam', 'Selesai'

  String _formatTimestamp(dynamic ts) {
    if (ts is! Timestamp) return '-';
    final dt = ts.toDate();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy • $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Peminjaman Alat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: ['Semua', 'Sedang Dipinjam', 'Selesai'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryDarkBlue,
                    backgroundColor: AppTheme.accentSkyBlue,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : AppTheme.primaryDarkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('borrowings')
                  .orderBy('borrow_date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat riwayat: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString();
                  if (_selectedFilter == 'Sedang Dipinjam') {
                    return status == 'Borrowed';
                  }
                  if (_selectedFilter == 'Selesai') {
                    return status == 'Returned';
                  }
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada riwayat peminjaman pada kategori ini.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final Map<String, Map<String, dynamic>> groupedItems = {};

                for (final doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String itemName =
                      (data['item_name'] ?? 'Alat Lab').toString().trim();
                  final String itemCode = (data['code'] ?? '-').toString().trim();
                  final String itemId = (data['item_id'] ?? '').toString().trim();

                  final String groupKey = itemId.isNotEmpty
                      ? itemId
                      : '${itemName.toLowerCase()}_${itemCode.toLowerCase()}';

                  final bool isBorrowedNow = data['status'] == 'Borrowed';

                  if (!groupedItems.containsKey(groupKey)) {
                    groupedItems[groupKey] = {
                      'item_name': itemName,
                      'code': itemCode,
                      'category': data['category'] ?? '-',
                      'image': data['image'] ?? '',
                      'count': 1,
                      'active_count': isBorrowedNow ? 1 : 0,
                      'latest_status': data['status'] ?? 'Returned',
                      'latest_borrow_date': data['borrow_date'],
                      'latest_return_date': data['return_date'],
                    };
                  } else {
                    groupedItems[groupKey]!['count'] =
                        (groupedItems[groupKey]!['count'] as int) + 1;
                    if (isBorrowedNow) {
                      groupedItems[groupKey]!['active_count'] =
                          (groupedItems[groupKey]!['active_count'] as int) + 1;
                      groupedItems[groupKey]!['latest_status'] = 'Borrowed';
                    }
                  }
                }

                final groupedList = groupedItems.values.toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: groupedList.length,
                  itemBuilder: (context, index) {
                    final item = groupedList[index];
                    final int borrowCount = item['count'] as int;
                    final int activeCount = item['active_count'] as int;
                    final bool hasActiveBorrow = activeCount > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['item_name'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDarkBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Kode: ${item['code'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentSkyBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Dipinjam ${borrowCount}x',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDarkBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasActiveBorrow
                                        ? Colors.orange.withOpacity(0.15)
                                        : Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hasActiveBorrow
                                        ? 'Sedang Dipinjam'
                                        : 'Selesai Dipinjam',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: hasActiveBorrow
                                          ? Colors.orange[800]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              children: [
                                const Icon(
                                  Icons.login_rounded,
                                  size: 15,
                                  color: AppTheme.secondaryLightBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pinjam Terakhir: ${_formatTimestamp(item['latest_borrow_date'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasActiveBorrow
                                      ? Icons.schedule
                                      : Icons.check_circle_outline,
                                  size: 15,
                                  color: hasActiveBorrow
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hasActiveBorrow
                                      ? 'Kembali: Belum dikembalikan'
                                      : 'Kembali Terakhir: ${_formatTimestamp(item['latest_return_date'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}