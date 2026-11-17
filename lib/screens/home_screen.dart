import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'inventaris_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _carouselController = PageController();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  int _currentBanner = 0;
  Timer? _carouselTimer;

  final _banners = [
    {
      'title': 'Peminjaman Alat Praktikum',
      'subtitle': 'Cek ketersediaan alat lab secara real-time',
      'image':
          'https://images.pexels.com/photos/2280571/pexels-photo-2280571.jpeg?auto=compress&cs=tinysrgb&w=800',
    },
    {
      'title': 'Jaga Kebersihan & Keamanan Lab',
      'subtitle': 'Kembalikan peralatan sesuai kondisi semula',
      'image':
          'https://images.pexels.com/photos/3735709/pexels-photo-3735709.jpeg?auto=compress&cs=tinysrgb&w=800',
    },
    {
      'title': 'Inventaris Terintegrasi Digital',
      'subtitle': 'Mendukung kegiatan praktikum siswa RPL',
      'image':
          'https://images.pexels.com/photos/3938022/pexels-photo-3938022.jpeg?auto=compress&cs=tinysrgb&w=800',
    },
  ];

  final List<String> _categories = const [
    'Semua',
    'Optik',
    'Alat Ukur',
    'Gelas Kimia',
    'Elektronika',
    'Mekanik',
    'Keselamatan Lab',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_carouselController.hasClients) {
        final nextPage = (_currentBanner + 1) % _banners.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName ?? '').trim().isNotEmpty
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Praktikan');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('iAlatLab'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Selamat datang, $userName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CAROUSEL BANNER
            SizedBox(
              height: 155,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _carouselController,
                      itemCount: _banners.length,
                      onPageChanged: (index) {
                        setState(() => _currentBanner = index);
                      },
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              banner['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.primaryDarkBlue,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryDarkBlue.withOpacity(0.90),
                                    AppTheme.secondaryLightBlue.withOpacity(0.55),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Halo, $userName!',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner['subtitle']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Positioned(
                      right: 16,
                      bottom: 12,
                      child: Row(
                        children: List.generate(_banners.length, (index) {
                          final isActive = _currentBanner == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Kolom Pencarian (Bisa cari Nama Alat, Kategori, maupun Kode)
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                  if (_searchQuery.isNotEmpty) {
                    _selectedCategory = 'Semua';
                  }
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
            const SizedBox(height: 16),

            // 3. Filter Kategori (ChoiceChip)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryDarkBlue,
                    backgroundColor: AppTheme.accentSkyBlue,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : AppTheme.primaryDarkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                        if (cat != 'Semua') {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // 4. Judul Section "Katalog Alat Laboratorium"
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Katalog Alat Laboratorium',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkBlue,
                  ),
                ),
                Text(
                  'Geser →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryLightBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Horizontal Scroll Section: Data Inventaris dari Firestore 'items'
            SizedBox(
              height: 255,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('items').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Gagal memuat alat: ${snapshot.error}',
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
                    final rawCategory =
                        (data['category'] ?? data['kategori'] ?? '').toString();
                    final categoryLower = rawCategory.toLowerCase();
                    final spec = (data['spesification'] ?? data['spec'] ?? '')
                        .toString()
                        .toLowerCase();

                    final matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        code.contains(_searchQuery) ||
                        categoryLower.contains(_searchQuery) ||
                        spec.contains(_searchQuery);

                    final matchesCategory = _selectedCategory == 'Semua' ||
                        categoryLower == _selectedCategory.toLowerCase();

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.accentSkyBlue.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada alat yang sesuai pencarian.',
                          style: TextStyle(color: AppTheme.primaryDarkBlue),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isAvailable = data['status'] == 'Available';

                      return Container(
                        width: 205,
                        margin: const EdgeInsets.only(right: 14, bottom: 4),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailInventarisScreen(itemId: doc.id),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Image.network(
                                      data['image'] ?? '',
                                      width: double.infinity,
                                      height: 115,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: double.infinity,
                                        height: 115,
                                        color: AppTheme.accentSkyBlue,
                                        child: const Icon(
                                          Icons.biotech,
                                          size: 42,
                                          color: AppTheme.primaryDarkBlue,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? Colors.green.shade600
                                              : Colors.orange.shade700,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          data['status'] ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['category'] ??
                                              data['kategori'] ??
                                              '-',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.secondaryLightBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          data['item_name'] ??
                                              data['name'] ??
                                              '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryDarkBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Kode: ${data['code'] ?? data['kode'] ?? '-'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const Spacer(),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 32,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      DetailInventarisScreen(
                                                          itemId: doc.id),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isAvailable
                                                  ? AppTheme.primaryDarkBlue
                                                  : Colors.grey.shade400,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              isAvailable
                                                  ? 'Lihat & Pinjam'
                                                  : 'Lihat Detail',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}