class User {
  String? password;
  final String id; // Ajout de l'identifiant
  final String name;
  final String email;
  final String mobileNumber;
  final String gender;
  final String address;
  final String image;

  User({
    required this.id, // Ajout dans le constructeur
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.gender,
    required this.address,
    this.password,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '', // Ajout dans la méthode fromJson
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      password: json['password'], // optional
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Ajout dans la méthode toJson
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'gender': gender,
      'address': address,
      'password': password,
      'image': image,
    };
  }
}