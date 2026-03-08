import 'dart:math';
import 'cuidador.dart';
import 'endereco.dart';

class CuidadorProximo {
  final Cuidador caregiver;
  final Endereco address;
  final double distance; // Distância em quilômetros
  final double hourlyRate; // Taxa por hora
  final bool isAvailable;

  CuidadorProximo({
    required this.caregiver,
    required this.address,
    required this.distance,
    required this.hourlyRate,
    this.isAvailable = true,
  });

  // Método para calcular a distância entre duas coordenadas usando a fórmula de Haversine
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raio da Terra em quilômetros

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Método para formatar a distância para exibição
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  // Método para formatar o preço por hora
  String get formattedHourlyRate {
    return 'R\$ ${hourlyRate.toStringAsFixed(2).replaceAll('.', ',')}/hora';
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiver': caregiver.toJson(),
      'address': address.toJson(),
      'distance': distance,
      'hourly_rate': hourlyRate,
      'is_available': isAvailable,
    };
  }

  factory CuidadorProximo.fromJson(Map<String, dynamic> json) {
    return CuidadorProximo(
      caregiver: Cuidador.fromJson(json['caregiver']),
      address: Endereco.fromJson(json['address']),
      distance: json['distance']?.toDouble() ?? 0.0,
      hourlyRate: json['hourly_rate']?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] ?? true,
    );
  }
}
