class Reservation {
  final String id;
  final String carRegistrationNumber;
  final String clientName;
  final String startDate;
  final String endDate;
  final double price;
  final String status;
  final String? location;
  final Map<String, dynamic>? car;
  final Map<String, dynamic>? driverDetails;
  final String createdAt;

  Reservation({
    required this.id,
    required this.carRegistrationNumber,
    required this.clientName,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.status,
    this.location,
    this.car,
    this.driverDetails,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id'] as String,
      carRegistrationNumber: json['carRegistrationNumber'] as String,
      clientName: json['clientName'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      price: (json['totalPrice'] as num).toDouble(),
      status: json['status'] as String,
      location: json['location'] as String?,
      car: json['car'] as Map<String, dynamic>?,
      driverDetails: json['driverDetails'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'carRegistrationNumber': carRegistrationNumber,
      'clientName': clientName,
      'startDate': startDate,
      'endDate': endDate,
      'totalPrice': price,
      'status': status,
      'location': location,
      'car': car,
      'driverDetails': driverDetails,
      'createdAt': createdAt,
    };
  }
} 