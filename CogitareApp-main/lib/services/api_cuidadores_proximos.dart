import 'dart:math';
import '../models/cuidador_proximo.dart';
import '../models/responsavel.dart';
import '../models/cuidador.dart';
import '../models/endereco.dart';
import 'api_client.dart';

/// Serviço de API para Cuidadores Próximos
class ApiCuidadoresProximos {
  /// Busca cuidadores próximos usando coordenadas padrão
  static Future<List<CuidadorProximo>> getNearby({
    double maxDistanceKm = 999999.0,
    int limit = 10,
  }) async {
    try {
      // Usa coordenadas de São Paulo como padrão
      final response = await ApiClient.get(
        '/api/nearby-caregivers/nearby/coordinates?latitude=-23.5505&longitude=-46.6333&max_distance=$maxDistanceKm&limit=$limit',
      );

      if (response['success'] == true) {
        final List<dynamic> caregiversData = response['data'];
        print('✅ Dados reais do banco carregados com sucesso!');
        return caregiversData
            .map((json) => CuidadorProximo.fromJson(json))
            .toList();
      }

      // Se não conseguiu buscar do backend, retorna dados mock
      print('⚠️ Backend não disponível - usando dados mock');
      return _getMockCuidadors(limit);
    } catch (e) {
      print('❌ Erro ao buscar cuidadores próximos: $e');
      print('🔄 Usando dados mock como fallback');
      return _getMockCuidadors(limit);
    }
  }

  /// Busca cuidadores próximos usando coordenadas específicas
  static Future<List<CuidadorProximo>> getNearbyByCoordinates({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 999999.0,
    int limit = 10,
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/nearby-caregivers/nearby/coordinates?latitude=$latitude&longitude=$longitude&max_distance=$maxDistanceKm&limit=$limit',
      );

      if (response['success'] == true) {
        final List<dynamic> caregiversData = response['data'];
        return caregiversData
            .map((json) => CuidadorProximo.fromJson(json))
            .toList();
      }

      return _getMockCuidadors(limit);
    } catch (e) {
      print('Erro ao buscar cuidadores próximos por coordenadas: $e');
      return _getMockCuidadors(limit);
    }
  }

  /// Busca cuidadores próximos com filtros
  static Future<List<CuidadorProximo>> search({
    required Responsavel guardian,
    double? maxDistanceKm,
    double? minHourlyRate,
    double? maxHourlyRate,
    bool? onlyAvailable,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'guardian_id': guardian.id.toString(),
        'max_distance': (maxDistanceKm ?? 999999.0).toString(),
        'limit': limit.toString(),
      };

      if (minHourlyRate != null) {
        queryParams['min_hourly_rate'] = minHourlyRate.toString();
      }
      if (maxHourlyRate != null) {
        queryParams['max_hourly_rate'] = maxHourlyRate.toString();
      }
      if (onlyAvailable == true) {
        queryParams['only_available'] = 'true';
      }

      final endpoint = '/api/nearby-caregivers/nearby?${Uri(queryParameters: queryParams).query}';
      final response = await ApiClient.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> caregiversData = response['data'];
        return caregiversData
            .map((json) => CuidadorProximo.fromJson(json))
            .toList();
      }

      return _getMockCuidadors(limit);
    } catch (e) {
      print('Erro ao buscar cuidadores próximos com filtros: $e');
      return _getMockCuidadors(limit);
    }
  }

  /// Busca cuidadores próximos por coordenadas com filtros
  static Future<List<CuidadorProximo>> searchByCoordinates({
    required double latitude,
    required double longitude,
    double? maxDistanceKm,
    double? minHourlyRate,
    double? maxHourlyRate,
    bool? onlyAvailable,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'max_distance': (maxDistanceKm ?? 999999.0).toString(),
        'limit': limit.toString(),
      };

      if (minHourlyRate != null) {
        queryParams['min_hourly_rate'] = minHourlyRate.toString();
      }
      if (maxHourlyRate != null) {
        queryParams['max_hourly_rate'] = maxHourlyRate.toString();
      }
      if (onlyAvailable == true) {
        queryParams['only_available'] = 'true';
      }

      final endpoint = '/api/nearby-caregivers/nearby/coordinates?${Uri(queryParameters: queryParams).query}';
      final response = await ApiClient.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> caregiversData = response['data'];
        return caregiversData
            .map((json) => CuidadorProximo.fromJson(json))
            .toList();
      }

      return _getMockCuidadors(limit);
    } catch (e) {
      print('Erro ao buscar cuidadores próximos por coordenadas com filtros: $e');
      return _getMockCuidadors(limit);
    }
  }

  /// Gera dados mock de cuidadores
  static List<CuidadorProximo> _getMockCuidadors(int limit) {
    final random = Random();
    final mockCuidadors = <CuidadorProximo>[];

    final names = [
      'Maria Silva',
      'João Santos',
      'Ana Costa',
      'Pedro Oliveira',
      'Carla Mendes',
      'Roberto Lima',
      'Fernanda Alves',
      'Carlos Pereira',
      'Lucia Rodrigues',
      'Antonio Ferreira',
    ];

    final cities = [
      'São Paulo',
      'Rio de Janeiro',
      'Belo Horizonte',
      'Salvador',
      'Brasília',
      'Fortaleza',
      'Manaus',
      'Curitiba',
      'Recife',
      'Porto Alegre',
    ];

    for (int i = 0; i < limit && i < names.length; i++) {
      final name = names[i];
      final city = cities[random.nextInt(cities.length)];
      final distance = 5.0 + random.nextDouble() * 50.0; // Entre 5 e 55 km
      final hourlyRate = 15.0 + random.nextDouble() * 35.0; // Entre R$ 15 e R$ 50
      final isAvailable = random.nextBool();

      final caregiver = Cuidador(
        id: i + 1,
        name: name,
        email: '${name.toLowerCase().replaceAll(' ', '.')}@email.com',
        phone: '(11) 99999-${1000 + i}',
        cpf: '123.456.789-0${i}',
        birthDate: DateTime(1980 + random.nextInt(20), random.nextInt(12) + 1,
            random.nextInt(28) + 1),
        photoUrl: null,
        biography:
            'Cuidador experiente com ${5 + random.nextInt(15)} anos de experiência.',
        smokingStatus: random.nextBool() ? 'Não' : 'Sim',
        hasChildren: random.nextBool() ? 'Sim' : 'Não',
        hasLicense: random.nextBool() ? 'Sim' : 'Não',
        hasCar: random.nextBool() ? 'Sim' : 'Não',
        hourlyRate: (50 + random.nextInt(100)).toString(),
      );

      final address = Endereco(
        id: i + 1,
        city: city,
        neighborhood: 'Centro',
        street: 'Rua das Flores',
        number: '${100 + i}',
        complement: 'Apto ${i + 1}',
        zipCode: '01234-${100 + i}',
      );

      mockCuidadors.add(CuidadorProximo(
        caregiver: caregiver,
        address: address,
        distance: distance,
        hourlyRate: hourlyRate,
        isAvailable: isAvailable,
      ));
    }

    return mockCuidadors;
  }
}

