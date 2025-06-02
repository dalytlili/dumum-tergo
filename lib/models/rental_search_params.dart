// models/rental_search_params.dart
import 'package:flutter/material.dart';

class RentalSearchParams {
  final String pickupLocation;
  final bool returnToSameLocation;
  final DateTime pickupDate;
  final DateTime returnDate;
  final TimeOfDay pickupTime;
  final TimeOfDay returnTime;
  final bool driverAgeBetween30And65;

  RentalSearchParams({
    required this.pickupLocation,
    required this.returnToSameLocation,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
    required this.driverAgeBetween30And65,
  });
}