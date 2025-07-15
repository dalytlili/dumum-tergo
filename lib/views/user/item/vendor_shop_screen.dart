import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/views/user/item/camping_item_card.dart';
import 'package:dumum_tergo/views/user/item/camping_item_detail.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorShopScreen extends StatefulWidget {
  final String vendorId;

  const VendorShopScreen({
    Key? key,
    required this.vendorId,
  }) : super(key: key);

  @override
  _VendorShopScreenState createState() => _VendorShopScreenState();
}

class _VendorShopScreenState extends State<VendorShopScreen> {
  late Future<List<CampingItem>> futureItems;
  Vendor? vendor;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 200.0;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    futureItems = fetchVendorItems();
    _scrollController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<CampingItem>> fetchVendorItems() async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/camping/items/vendor/${widget.vendorId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final itemsData = data['data'] as List;
          
          if (itemsData.isNotEmpty) {
            setState(() {
              vendor = Vendor.fromJson(itemsData[0]['vendor']);
            });
          }
          
          return itemsData.map((item) => CampingItem.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to load items');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchVendorRatings() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/${widget.vendorId}/ratings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load ratings');
    }
  }

  Future<void> _createComplaint() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final token = await storage.read(key: 'token');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => ComplaintDialog(),
    );

    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:9098/api/complaints'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'vendorId': widget.vendorId,
            'title': result['title'],
            'description': result['description'],
          }),
        );

        if (response.statusCode == 201) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Réclamation créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to create complaint');
        }
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double expandedHeight = _imageHeight + appBarHeight + statusBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<CampingItem>>(
        future: futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucun article disponible dans cette boutique'),
            );
          } else {
            final items = snapshot.data!;
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: expandedHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/welcome_illustration.png',
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        if (vendor != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: _buildVendorInfoOverlay(context, vendor!),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(
                      'Articles (${items.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.59,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return CampingItemCard(
                          item: items[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CampingItemDetailScreen(item: items[index], fromShop: true),
                              ),
                            );
                          },
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildVendorInfoOverlay(BuildContext context, Vendor vendor) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchVendorRatings(),
      builder: (context, snapshot) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: vendor.image != null
                  ? NetworkImage('https://res.cloudinary.com/dcs2edizr/image/upload/${vendor.image!}')
                  : const AssetImage('assets/default.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.businessName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'complaint') {
                            _createComplaint();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'complaint',
                            child: Row(
                              children: [
                                Icon(Icons.report_problem, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Signaler un problème'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (vendor.businessAddress != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vendor.businessAddress!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (vendor.description != null && vendor.description!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vendor.description!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Text('Chargement...', 
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      if (snapshot.hasError)
                        const Text('Erreur de chargement', 
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      if (snapshot.hasData)
                        Text(
                          '${snapshot.data?['averageRating']?.toStringAsFixed(1) ?? '0.0'} '
                          '(${snapshot.data?['ratingCount'] ?? 0} ${snapshot.data?['ratingCount'] == 1 ? 'avis' : 'avis'})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ComplaintDialog extends StatefulWidget {
  @override
  _ComplaintDialogState createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<ComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nouvelle réclamation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Titre de la réclamation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Décrivez brièvement le problème',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.outline.withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode 
                      ? colors.surfaceVariant.withOpacity(0.5)
                      : colors.surfaceVariant.withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(fontSize: 15),
                validator: (value) => value?.isEmpty ?? true 
                    ? 'Veuillez saisir un titre' 
                    : null,
              ),
              SizedBox(height: 20),
              Text(
                'Description détaillée',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Décrivez le problème en détails...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.outline.withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode 
                      ? colors.surfaceVariant.withOpacity(0.5)
                      : colors.surfaceVariant.withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLines: 5,
                style: TextStyle(fontSize: 15),
                validator: (value) => value?.isEmpty ?? true 
                    ? 'Veuillez saisir une description' 
                    : null,
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.pop(context, {
                          'title': _titleController.text,
                          'description': _descriptionController.text,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Envoyer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}