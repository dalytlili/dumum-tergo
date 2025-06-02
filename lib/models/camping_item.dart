// models/camping_item.dart
class CampingItem {
  late final String id;
  final String name;
  final String description;
  final double price;
  final double rentalPrice;
  final String category;
  final List<String> images;
  final int? stock;
  final bool isForSale;
  final bool isForRent;
  final Location location;
  final Vendor vendor;
  final String? condition; // Optionnel
  final String? rentalTerms;
  final DateTime createdAt;

  CampingItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rentalPrice,
    required this.category,
    required this.images,
     this.stock,
    this.isForSale = false, // Valeur par défaut false
    this.isForRent = false, // Valeur par défaut false
    required this.location,
    required this.vendor,
    this.condition, // Optionnel
     this.rentalTerms,
    required this.createdAt,
  });

  factory CampingItem.fromJson(Map<String, dynamic> json) {
    return CampingItem(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      rentalPrice: json['rentalPrice'].toDouble(),
      category: json['category'],
      images: List<String>.from(json['images']),
      stock: json['stock'],
      isForSale: json['isForSale'] ?? false, // Valeur par défaut si null
      isForRent: json['isForRent'] ?? false, // Valeur par défaut si null
      location: Location.fromJson(json['location']),
      vendor: Vendor.fromJson(json['vendor']),
      condition: json['condition'], // Peut être null
      rentalTerms: json['rentalTerms'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

static bool isValidJson(Map<String, dynamic> json) {
  try {
    // Vérifiez les champs obligatoires
    return json['id'] != null && 
           json['name'] != null && 
           json['createdAt'] != null;
  } catch (e) {
    return false;
  }
}
}

class Vendor {
  final String id;
  final String mobile; // Changé en nullable
  final String? image;  // Changé en nullable
  final String businessName;
  final String? businessAddress;
  final String? description;
  final String? email;

  Vendor({
    required String id,
    required this.mobile,        // Retiré required
    this.image,         // Retiré required
    required this.businessName,
    this.businessAddress,
    this.description,
    this.email,
  }) : id = id;

  // Ajoutez une méthode fromJson
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'] ?? '',
      mobile: json['mobile'],
      image: json['image'],
      businessName: json['businessName'] ?? 'Nom inconnu',
      businessAddress: json['businessAddress'],
      description: json['description'],
      email: json['email'],
    );
  }
}
class Location {
  final String id;
  final String title;
    final String subtitle;


  Location({
    required this.id,
    required this.title,
        required this.subtitle,

  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'],
      title: json['title'],
            subtitle: json['subtitle'],

    );
  }
}