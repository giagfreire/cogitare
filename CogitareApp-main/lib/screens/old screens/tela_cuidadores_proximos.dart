import 'package:flutter/material.dart';
import '../widgets/widget_cuidadores_proximos.dart';
import '../models/responsavel.dart';
import '../services/api_cuidadores_proximos.dart';
import '../models/cuidador_proximo.dart';

class TelaCuidadoresProximos extends StatefulWidget {
  static const route = '/cuidadores-proximos';
  const TelaCuidadoresProximos({super.key});

  @override
  State<TelaCuidadoresProximos> createState() => _TelaCuidadoresProximosState();
}

class _TelaCuidadoresProximosState extends State<TelaCuidadoresProximos> {
  final Responsavel _guardian = Responsavel(
    id: 1,
    addressId: 1,
    cpf: '123.456.789-00',
    name: 'João Maria',
    email: 'joao@email.com',
    phone: '(11) 99999-9999',
    birthDate: DateTime(1980, 1, 1),
  );

  double _maxDistance = 999999.0; // Busca em qualquer lugar do mundo
  double _minHourlyRate = 0.0;
  double _maxHourlyRate = 100.0;
  bool _onlyAvailable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cuidadores Próximos'),
        backgroundColor: const Color(0xFF28323C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                // Filtro de distância
                Row(
                  children: [
                    const Text('Distância máxima: '),
                    Expanded(
                      child: Slider(
                        value: _maxDistance,
                        min: 5.0,
                        max: 10000.0, // Até 10.000km
                        divisions: 20,
                        label: _maxDistance >= 1000
                            ? '${(_maxDistance / 1000).toStringAsFixed(1)}k km'
                            : '${_maxDistance.round()}km',
                        onChanged: (value) {
                          setState(() {
                            _maxDistance = value;
                          });
                        },
                      ),
                    ),
                    Text(_maxDistance >= 1000
                        ? '${(_maxDistance / 1000).toStringAsFixed(1)}k km'
                        : '${_maxDistance.round()}km'),
                  ],
                ),

                // Filtro de preço
                Row(
                  children: [
                    const Text('Preço: '),
                    Expanded(
                      child: RangeSlider(
                        values: RangeValues(_minHourlyRate, _maxHourlyRate),
                        min: 0.0,
                        max: 100.0,
                        divisions: 20,
                        labels: RangeLabels(
                          'R\$ ${_minHourlyRate.toStringAsFixed(0)}',
                          'R\$ ${_maxHourlyRate.toStringAsFixed(0)}',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _minHourlyRate = values.start;
                            _maxHourlyRate = values.end;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Filtro de disponibilidade
                Row(
                  children: [
                    Checkbox(
                      value: _onlyAvailable,
                      onChanged: (value) {
                        setState(() {
                          _onlyAvailable = value ?? false;
                        });
                      },
                    ),
                    const Text('Apenas disponíveis'),
                  ],
                ),
              ],
            ),
          ),

          // Lista de cuidadores
          Expanded(
            child: WidgetCuidadoresProximos(
              guardian: _guardian,
              maxDistanceKm: _maxDistance,
              limit: 20,
              onCaregiverTap: _onCaregiverTap,
              onSeeMoreTap: _onSeeMoreTap,
            ),
          ),
        ],
      ),
    );
  }

  void _onCaregiverTap(CuidadorProximo caregiver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(caregiver.caregiver.name ?? 'Cuidador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preço: ${caregiver.formattedHourlyRate}'),
            Text('Distância: ${caregiver.formattedDistance}'),
            Text('Disponível: ${caregiver.isAvailable ? 'Sim' : 'Não'}'),
            if (caregiver.caregiver.biography != null) ...[
              const SizedBox(height: 8),
              const Text('Biografia:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(caregiver.caregiver.biography!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _contactCaregiver(caregiver);
            },
            child: const Text('Contatar'),
          ),
        ],
      ),
    );
  }

  void _onSeeMoreTap() {
    // Implementar busca com filtros aplicados
    _searchWithFilters();
  }

  void _searchWithFilters() async {
    try {
      final caregivers = await ApiCuidadoresProximos.search(
        guardian: _guardian,
        maxDistanceKm: _maxDistance,
        minHourlyRate: _minHourlyRate,
        maxHourlyRate: _maxHourlyRate,
        onlyAvailable: _onlyAvailable,
        limit: 50,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Resultados da Busca'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: caregivers.length,
                itemBuilder: (context, index) {
                  final caregiver = caregivers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(caregiver.caregiver.name?[0] ?? '?'),
                    ),
                    title:
                        Text(caregiver.caregiver.name ?? 'Nome não informado'),
                    subtitle: Text(
                        '${caregiver.formattedHourlyRate} - ${caregiver.formattedDistance}'),
                    trailing: caregiver.isAvailable
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.red),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na busca: $e')),
        );
      }
    }
  }

  void _contactCaregiver(CuidadorProximo caregiver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contatando ${caregiver.caregiver.name}...'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}
