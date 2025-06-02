// model.dart

class CarRental {
  String? brand;
  String? model;
  String? year;
  String? registrationNumber;
  String? color;
  String? seats;
  String? pricePerDay;
  String? transmission;
  String? mileagePolicy;
  String? location;
  String? deposit;
  String? description;
  List<String> features;
  List<String> images;

  CarRental({
    this.brand,
    this.model,
    this.year,
    this.registrationNumber,
    this.color,
    this.seats,
    this.pricePerDay,
    this.transmission,
    this.mileagePolicy,
    this.location,
    this.deposit,
    this.description,
    this.features = const [],
    this.images = const [],
  });
}
