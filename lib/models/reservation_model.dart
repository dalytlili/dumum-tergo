// reservation_model.dart
class Reservation {
  final String id;
  final Car car;
  final Vendor vendor;
  final DriverDetails driverDetails;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String location;

  Reservation({
    required this.id,
    required this.car,
    required this.vendor,
    required this.driverDetails,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.location,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id'],
      car: Car.fromJson(json['car']),
      vendor: Vendor.fromJson(json['vendor']),
      driverDetails: DriverDetails.fromJson(json['driverDetails']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalPrice: json['totalPrice'].toDouble(),
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      location: json['location'],
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
  final String image;
  final String businessName;

  Vendor({
    required this.id,
    required this.image,
    required this.businessName,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'],
      image: json['image'],
      businessName: json['businessName'],
    );
  }
}

class DriverDetails {
  final String email;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String phoneNumber;
  final String country;

  DriverDetails({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.phoneNumber,
    required this.country,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: DateTime.parse(json['birthDate']),
      phoneNumber: json['phoneNumber'],
      country: json['country'],
    );
  }
}