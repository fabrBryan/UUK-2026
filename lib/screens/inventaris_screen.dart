import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class InventarisScreen extends StatefulWidget {
  const InventarisScreen({super.key});

  @override
  State<InventarisScreen> createState() => _InventarisScreenState();
}

class _InventarisScreenState extends State<InventarisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua'; // 'Semua', 'Available', 'Borrowed'

  final List<String> _categories = const [
    'Optik',
    'Alat Ukur',
    'Gelas Kimia',
    'Elektronika',
    'Mekanik',
    'Keselamatan Lab',
    'Lainnya',
  ];

  bool get isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    return email == 'bryan456@gmail.com';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  //kode revisian
  void _showItemFormDialog({DocumentSnapshot? existingDoc}) {
    final bool isEdit = existingDoc != null;
    final data = existingDoc?.data() as Map<String, dynamic>?;

    if (isEdit && data?['status'] == 'Borrowed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alat yang sedang dipinjam tidak dapat diedit!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: data?['item_name'] ?? data?['name'] ?? '');
    final codeController =
        TextEditingController(text: data?['code'] ?? data?['kode'] ?? '');
    final specController =
        TextEditingController(text: data?['spesification'] ?? '');
    final imageController = TextEditingController(text: data?['image'] ?? '');

    final rawCat = (data?['category'] ?? data?['kategori'] ?? '').toString();
    String selectedCategory =
        _categories.contains(rawCat) ? rawCat : _categories.first;
    String selectedStatus =
        (data?['status'] == 'Borrowed') ? 'Borrowed' : 'Available';
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
                isEdit ? 'Edit Alat Inventaris' : 'Tambah Alat Inventaris',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkBlue,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Alat *',
                            hintText: 'Contoh: Mikroskop Binokuler',
                            prefixIcon: Icon(Icons.biotech_outlined),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Nama alat wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori *',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Kode Serial Alat *',
                            hintText: 'Contoh: LAB-OPT-001',
                            prefixIcon: Icon(Icons.qr_code_2),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Kode serial wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: specController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Spesifikasi Alat *',
                            hintText: 'Tuliskan detail spesifikasi & fungsi alat...',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Spesifikasi wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: 'URL Gambar Alat *',
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'URL gambar wajib diisi';
                            }
                            if (!val.trim().startsWith('http://') &&
                                !val.trim().startsWith('https://')) {
                              return 'URL harus diawali http:// atau https://';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status Ketersediaan',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Available',
                              child: Text('Available (Tersedia)'),
                            ),
                            DropdownMenuItem(
                              value: 'Borrowed',
                              child: Text('Borrowed (Dipinjam)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedStatus = val);
                            }
                          },
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
                            final collection =
                                FirebaseFirestore.instance.collection('items');
                            final String formattedImg =
                                _formatImageUrl(imageController.text);

                            if (isEdit) {
                              final Map<String, dynamic> updatePayload = {
                                'item_name': nameController.text.trim(),
                                'category': selectedCategory,
                                'code': codeController.text.trim(),
                                'spesification': specController.text.trim(),
                                'image': formattedImg,
                                'status': selectedStatus,
                              };
                              if (selectedStatus == 'Available') {
                                updatePayload['borrowed_by'] = '';
                                updatePayload['borrower_name'] = '';
                                updatePayload['purpose'] = ''; //kode revisian
                              }
                              await collection
                                  .doc(existingDoc.id)
                                  .update(updatePayload);
                            } else {
                              final newDoc = collection.doc();
                              await newDoc.set({
                                'item_id': newDoc.id,
                                'item_name': nameController.text.trim(),
                                'category': selectedCategory,
                                'code': codeController.text.trim(),
                                'spesification': specController.text.trim(),
                                'image': formattedImg,
                                'status': selectedStatus,
                                'borrowed_by': '',
                                'borrower_name': '',
                                'purpose': '', //kode revisian
                                'created_at': FieldValue.serverTimestamp(),
                              });
                            }

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Alat berhasil diperbarui!'
                                      : 'Alat baru berhasil ditambahkan!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menyimpan data: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(
                    isSaving
                        ? 'Menyimpan...'
                        : (isEdit ? 'Simpan Perubahan' : 'Tambah Alat'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndDeleteItem(String itemId, String itemName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Alat Lab',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDarkBlue,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "$itemName" dari inventaris?',
        ),
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

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$itemName" berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus alat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _returnBorrowedItem({
    required String userId,
    required String borrowId,
    required String itemId,
    required String itemName,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kembalikan Alat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDarkBlue,
          ),
        ),
        content: Text(
          'Pastikan alat "$itemName" dalam kondisi bersih dan baik. Lanjutkan pengembalian?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kembalikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('borrowings')
          .doc(borrowId)
          .update({
        'status': 'Returned',
        'return_date': FieldValue.serverTimestamp(),
      });

      if (itemId.isNotEmpty) {
        final itemDoc = await FirebaseFirestore.instance
            .collection('items')
            .doc(itemId)
            .get();
        if (itemDoc.exists) {
          await FirebaseFirestore.instance
              .collection('items')
              .doc(itemId)
              .update({
            'status': 'Available',
            'borrowed_by': '',
            'borrower_name': '',
            'purpose': '',
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$itemName" berhasil dikembalikan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengembalikan alat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAllItemsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama alat, kategori, atau kode...',
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
              const SizedBox(height: 10),
              Row(
                children: ['Semua', 'Available', 'Borrowed'].map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        status == 'Semua'
                            ? 'Semua'
                            : (status == 'Available' ? 'Tersedia' : 'Dipinjam'),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryDarkBlue,
                      backgroundColor: AppTheme.accentSkyBlue,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.primaryDarkBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedStatusFilter = status),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('items').snapshots(),
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

              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['item_name'] ?? data['name'] ?? '')
                    .toString()
                    .toLowerCase();
                final code = (data['code'] ?? data['kode'] ?? '')
                    .toString()
                    .toLowerCase();
                final category = (data['category'] ?? data['kategori'] ?? '')
                    .toString()
                    .toLowerCase();
                final spec = (data['spesification'] ?? data['spec'] ?? '')
                    .toString()
                    .toLowerCase();
                final status = (data['status'] ?? 'Available').toString();

                final matchesSearch = _searchQuery.isEmpty ||
                    name.contains(_searchQuery) ||
                    code.contains(_searchQuery) ||
                    category.contains(_searchQuery) ||
                    spec.contains(_searchQuery);
                final matchesStatus = _selectedStatusFilter == 'Semua' ||
                    status == _selectedStatusFilter;

                return matchesSearch && matchesStatus;
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada alat yang sesuai pencarian.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isAvailable = data['status'] == 'Available';
                  final String borrowerName =
                      (data['borrower_name'] ?? '').toString().trim();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailInventarisScreen(itemId: doc.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                data['image'] ?? '',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppTheme.accentSkyBlue,
                                  child: const Icon(
                                    Icons.biotech,
                                    size: 34,
                                    color: AppTheme.primaryDarkBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['item_name'] ?? data['name'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDarkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${data['category'] ?? data['kategori'] ?? '-'} • Kode: ${data['code'] ?? data['kode'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? Colors.green.withOpacity(0.12)
                                              : Colors.orange.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isAvailable
                                              ? 'Available'
                                              : 'Borrowed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isAvailable
                                                ? Colors.green[700]
                                                : Colors.orange[800],
                                          ),
                                        ),
                                      ),
                                      if (!isAvailable &&
                                          borrowerName.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Oleh: $borrowerName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            //kode revisian
                            if (isAdmin)
                              if (!isAvailable)
                                Tooltip(
                                  message:
                                      'Alat sedang dipinjam, tidak dapat diedit/dihapus',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Alat sedang dipinjam user, tidak dapat diedit atau dihapus!',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppTheme.primaryDarkBlue,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showItemFormDialog(existingDoc: doc);
                                    } else if (value == 'delete') {
                                      _confirmAndDeleteItem(
                                        doc.id,
                                        data['item_name'] ?? 'alat ini',
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: AppTheme.primaryDarkBlue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Hapus',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                            else
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.secondaryLightBlue,
                              ),
                            // === SAMPAI SINI ===
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecondTab() {
    if (isAdmin) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('status', isEqualTo: 'Borrowed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat data: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final borrowedItems = snapshot.data?.docs ?? [];
          if (borrowedItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Semua alat saat ini tersedia di laboratorium.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: borrowedItems.length,
            itemBuilder: (context, index) {
              final doc = borrowedItems[index];
              final data = doc.data() as Map<String, dynamic>;
              final String purpose = (data['purpose'] ?? '').toString().trim(); //kode revisian

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['image'] ?? '',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 54,
                        height: 54,
                        color: AppTheme.accentSkyBlue,
                        child: const Icon(
                          Icons.biotech,
                          color: AppTheme.primaryDarkBlue,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    data['item_name'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkBlue,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'Kode: ${data['code'] ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Alasan: ${purpose.isNotEmpty ? purpose : '-'}', //kode revisian
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Peminjam: ${data['borrower_name'] ?? 'Siswa'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Dipinjam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login terlebih dahulu.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('borrowings')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat pinjaman: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final activeBorrows = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Borrowed';
        }).toList();

        if (activeBorrows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 56,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 10),
                Text(
                  'Kamu tidak memiliki pinjaman alat yang aktif.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeBorrows.length,
          itemBuilder: (context, index) {
            final doc = activeBorrows[index];
            final data = doc.data() as Map<String, dynamic>;

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
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['image'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: AppTheme.accentSkyBlue,
                              child: const Icon(
                                Icons.biotech,
                                color: AppTheme.primaryDarkBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['item_name'] ?? 'Alat Lab',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kode: ${data['code'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if ((data['purpose'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                Text(
                                  'Keperluan: ${data['purpose']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _returnBorrowedItem(
                          userId: user.uid,
                          borrowId: doc.id,
                          itemId: (data['item_id'] ?? '').toString(),
                          itemName: (data['item_name'] ?? 'Alat Lab').toString(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.assignment_return,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Kembalikan Alat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isAdmin ? 'Kelola Inventaris (Admin)' : 'Inventaris Alat'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: 'Daftar Alat'),
            Tab(text: isAdmin ? 'Monitoring Pinjaman' : 'Pinjaman Saya'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllItemsTab(),
          _buildSecondTab(),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showItemFormDialog(),
              backgroundColor: AppTheme.primaryDarkBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Alat Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

// ===========================================================================
// HALAMAN DETAIL INVENTARIS & PENGAJUAN PINJAM
// ===========================================================================
class DetailInventarisScreen extends StatefulWidget {
  final String itemId;

  const DetailInventarisScreen({super.key, required this.itemId});

  @override
  State<DetailInventarisScreen> createState() => _DetailInventarisScreenState();
}

class _DetailInventarisScreenState extends State<DetailInventarisScreen> {
  final TextEditingController _purposeController = TextEditingController();
  bool _isSubmitting = false;

  bool get isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    return email == 'bryan456@gmail.com';
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  void _showBorrowConfirmationDialog(Map<String, dynamic> itemData) {
    _purposeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Pengajuan Peminjaman Alat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkBlue,
            ),
          ),
          content: Column(
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
                  labelText: 'Keperluan / Alasan Peminjaman',
                  hintText: 'Contoh: Praktikum Fisika Optik',
                ),
              ),
            ],
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

  Future<void> _submitBorrowRequest(Map<String, dynamic> itemData) async {
    User? user = FirebaseAuth.instance.currentUser;
    user ??= await FirebaseAuth.instance.authStateChanges().first;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login telah berakhir. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String borrowerName = (user.displayName ?? '').trim();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final uData = userDoc.data();
        if ((uData?['name'] ?? '').toString().trim().isNotEmpty) {
          borrowerName = uData!['name'].toString().trim();
        }
      }
      if (borrowerName.isEmpty) {
        borrowerName = user.email?.split('@').first ?? 'Siswa';
      }

      final String purposeText = _purposeController.text.trim(); //kode revisian

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
        'borrower_name': borrowerName,
        'purpose': purposeText, //kode revisian
        'status': 'Borrowed',
        'borrow_date': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .update({
        'status': 'Borrowed',
        'borrowed_by': user.uid,
        'borrower_name': borrowerName,
        'purpose': purposeText,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil mengajukan peminjaman alat!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses peminjaman: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                'Gagal memuat detail: ${snapshot.error}',
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
          final bool isAvailable = data['status'] == 'Available';
          final String borrowerName =
              (data['borrower_name'] ?? '').toString().trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
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
                            size: 64,
                            color: AppTheme.primaryDarkBlue,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.shade600
                              : Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['status'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  data['category'] ?? data['kategori'] ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryLightBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['item_name'] ?? data['name'] ?? '-',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSkyBlue.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            color: AppTheme.primaryDarkBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Kode Serial:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['code'] ?? data['kode'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isAvailable
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: isAvailable
                                ? Colors.green[700]
                                : Colors.orange[800],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAvailable
                                  ? 'Tersedia untuk dipinjam'
                                  : 'Sedang dipinjam${borrowerName.isNotEmpty ? ' oleh $borrowerName' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? Colors.green[800]
                                    : Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    data['spesification'] ?? 'Tidak ada keterangan spesifikasi.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isAdmin)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (isAvailable && !_isSubmitting)
                          ? () => _showBorrowConfirmationDialog(data)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvailable
                            ? AppTheme.primaryDarkBlue
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isAvailable
                                  ? Icons.assignment_turned_in
                                  : Icons.block,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Memproses Peminjaman...'
                            : (isAvailable
                                ? 'Ajukan Peminjaman Alat'
                                : 'Alat Sedang Dipinjam'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSkyBlue.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: AppTheme.primaryDarkBlue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mode Admin: Kelola alat melalui tab Inventaris',
                          style: TextStyle(
                            color: AppTheme.primaryDarkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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