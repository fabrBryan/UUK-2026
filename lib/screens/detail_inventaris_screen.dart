import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DetailInventarisScreen extends StatefulWidget {
  final String itemId;

  const DetailInventarisScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<DetailInventarisScreen> createState() => _DetailInventarisScreenState();
}

class _DetailInventarisScreenState extends State<DetailInventarisScreen> {
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submitBorrowRequest(Map<String, dynamic> itemData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Ambil nama lengkap peminjam dari Firestore users atau displayName Auth
      String borrowerName = user.displayName ?? '';
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if ((userData['name'] ?? '').toString().trim().isNotEmpty) {
          borrowerName = userData['name'].toString().trim();
        }
      }
      if (borrowerName.isEmpty) {
        borrowerName = user.email ?? 'Pengguna Lab';
      }

      // 1. Tambah dokumen baru ke Firestore: users/{uid}/borrowings/{borrowId}
      final borrowRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('borrowings')
          .doc();

      await borrowRef.set({
        'borrow_id': borrowRef.id,
        'item_id': widget.itemId,
        'item_name': itemData['item_name'] ?? 'Alat Lab',
        'code': itemData['code'] ?? '-',
        'category': itemData['category'] ?? '-',
        'image': itemData['image'] ?? '',
        'purpose': _purposeController.text.trim(),
        'status': 'Borrowed',
        'borrow_date': FieldValue.serverTimestamp(),
      });

      // 2. Perbarui status alat di koleksi items menjadi Borrowed
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .update({
        'status': 'Borrowed',
        'borrowed_by': user.uid,
        'borrower_name': borrowerName,
      });

      if (!mounted) return;
      _purposeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengajuan pinjam ${itemData['item_name'] ?? 'alat'} berhasil!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan peminjaman: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showBorrowConfirmationDialog(Map<String, dynamic> itemData) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Ajukan Peminjaman Alat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkBlue,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alat: ${itemData['item_name'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Kode Serial: ${itemData['code'] ?? '-'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _purposeController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Keperluan Peminjaman (Opsional)',
                    hintText: 'Contoh: Praktikum Fisika Dasar',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _submitBorrowRequest(itemData);
              },
              child: const Text('Konfirmasi Pinjam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Inventaris'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .doc(widget.itemId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data alat tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String itemName = data['item_name'] ?? '-';
          final String category = data['category'] ?? '-';
          final String code = data['code'] ?? '-';
          final String status = data['status'] ?? 'Unknown';
          final bool isAvailable = status == 'Available';
          final String borrowerName =
              (data['borrower_name'] ?? '').toString().trim();
          final String specification = data['spesification'] ??
              data['specification'] ??
              data['description'] ??
              'Tidak ada keterangan spesifikasi.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Alat
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    data['image'] ?? '',
                    width: double.infinity,
                    height: 230,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 230,
                      color: AppTheme.accentSkyBlue,
                      child: const Icon(
                        Icons.biotech,
                        size: 72,
                        color: AppTheme.primaryDarkBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Badge Kategori & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentSkyBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.schedule,
                            size: 16,
                            color: isAvailable
                                ? Colors.green[700]
                                : Colors.orange[800],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Nama Alat
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Kode Serial & Info Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            color: AppTheme.primaryDarkBlue,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Kode Serial:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkBlue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Row(
                        children: [
                          Icon(
                            isAvailable
                                ? Icons.verified_outlined
                                : Icons.person_outline,
                            color: isAvailable
                                ? Colors.green[700]
                                : Colors.orange[800],
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Keterangan:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              isAvailable
                                  ? 'Tersedia untuk dipinjam'
                                  : (borrowerName.isNotEmpty
                                      ? 'Dipinjam oleh $borrowerName'
                                      : 'Sedang dipinjam'),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? Colors.green[700]
                                    : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Spesifikasi Alat
                const Text(
                  'Spesifikasi Alat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSkyBlue.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    specification,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Pengajuan Pinjam
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (isAvailable && !_isSubmitting)
                        ? () => _showBorrowConfirmationDialog(data)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDarkBlue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      isAvailable ? Icons.assignment_add : Icons.lock_clock,
                      color: isAvailable ? Colors.white : Colors.grey.shade600,
                    ),
                    label: Text(
                      _isSubmitting
                          ? 'Memproses Pengajuan...'
                          : (isAvailable
                              ? 'Ajukan Peminjaman Alat'
                              : 'Alat Sedang Dipinjam'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            isAvailable ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}