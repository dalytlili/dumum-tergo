class Reservation {
  final String id;
  final Car car;
  final Vendor vendor;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String location;
  final int childSeats;
  final int additionalDrivers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DriverDocuments documents;
  final DriverDetails driverDetails;

  Reservation({
    required this.id,
    required this.car,
    required this.vendor,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.location,
    required this.childSeats,
    required this.additionalDrivers,
    required this.createdAt,
    required this.updatedAt,
    required this.documents,
    required this.driverDetails,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id'],
      car: Car.fromJson(json['car']),
      vendor: Vendor.fromJson(json['vendor']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalPrice: json['totalPrice'].toDouble(),
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      location: json['location'],
      childSeats: json['childSeats'],
      additionalDrivers: json['additionalDrivers'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      documents: DriverDocuments.fromJson(json['documents']),
      driverDetails: DriverDetails.fromJson(json['driverDetails']),
    );
  }
}

class Car {
  final String id;
  final String brand;
  final String model;
  final List<String> images;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.images,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['_id'],
      brand: json['brand'],
      model: json['model'],
      images: List<String>.from(json['images']),
    );
  }
}

class Vendor {
  final String id;
  final String businessName;
  final String image;

  Vendor({
    required this.id,
    required this.businessName,
    required this.image,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'],
      businessName: json['businessName'],
      image: json['image'],
    );
  }
}

class DriverDocuments {
  final String? permisRecto;
  final String? permisVerso;
  final String? passport;
  final String? cinRecto;
  final String? cinVerso;

  DriverDocuments({
    this.permisRecto,
    this.permisVerso,
    this.passport,
        this.cinRecto,
        this.cinVerso,

  });

  factory DriverDocuments.fromJson(Map<String, dynamic> json) {
    return DriverDocuments(
      permisRecto: json['permisRecto'],
      permisVerso: json['permisVerso'],
      passport: json['passport'],
            cinRecto: json['cinRecto'],
            cinVerso: json['cinVerso'],

    );
  }
}

class DriverDetails {
  final String email;
  final String phoneNumber;

  DriverDetails({
    required this.email,
    required this.phoneNumber,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      email: json['email'],
      phoneNumber: json['phoneNumber'],
    );
  }
}