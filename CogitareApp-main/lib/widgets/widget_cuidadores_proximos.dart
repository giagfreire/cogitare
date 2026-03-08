import 'package:flutter/material.dart';
import '../models/cuidador_proximo.dart';
import '../models/responsavel.dart';
import '../services/api_cuidadores_proximos.dart';

class WidgetCuidadoresProximos extends StatefulWidget {
  final Responsavel guardian;
  final double? maxDistanceKm;
  final int limit;
  final Function(CuidadorProximo)? onCaregiverTap;
  final VoidCallback? onSeeMoreTap;

  const WidgetCuidadoresProximos({
    super.key,
    required this.guardian,
    this.maxDistanceKm,
    this.limit = 10,
    this.onCaregiverTap,
    this.onSeeMoreTap,
  });

  @override
  State<WidgetCuidadoresProximos> createState() =>
      _WidgetCuidadoresProximosState();
}

class _WidgetCuidadoresProximosState extends State<WidgetCuidadoresProximos> {
  List<CuidadorProximo> _caregivers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCuidadorProximos();
  }

  Future<void> _loadCuidadorProximos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final caregivers = await ApiCuidadoresProximos.getNearby(
        maxDistanceKm: widget.maxDistanceKm ?? 50.0,
        limit: widget.limit,
      );

      setState(() {
        _caregivers = caregivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(
              Icons.home,
              color: Color(0xFF28323C),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Profissionais perto de você',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF28323C),
              ),
            ),
            const Spacer(),
            // Indicador de dados mock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 12,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Conteúdo
        if (_isLoading)
          const _LoadingWidget()
        else if (_error != null)
          _ErrorWidget(
            error: _error!,
            onRetry: _loadCuidadorProximos,
          )
        else if (_caregivers.isEmpty)
          const _EmptyWidget()
        else
          _CaregiversList(
            caregivers: _caregivers,
            onCaregiverTap: widget.onCaregiverTap,
            onSeeMoreTap: widget.onSeeMoreTap,
          ),
      ],
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(
          color: Color(0xFF28323C),
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar cuidadores',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum cuidador encontrado',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Não há cuidadores disponíveis na sua região',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CaregiversList extends StatelessWidget {
  final List<CuidadorProximo> caregivers;
  final Function(CuidadorProximo)? onCaregiverTap;
  final VoidCallback? onSeeMoreTap;

  const _CaregiversList({
    required this.caregivers,
    this.onCaregiverTap,
    this.onSeeMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista de cuidadores
        ...caregivers.map((caregiver) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CaregiverCard(
                caregiver: caregiver,
                onTap: () => onCaregiverTap?.call(caregiver),
              ),
            )),

        const SizedBox(height: 16),

        // Botão Ver mais
        GestureDetector(
          onTap: onSeeMoreTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF28323C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ver mais',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  final CuidadorProximo caregiver;
  final VoidCallback? onTap;

  const _CaregiverCard({
    required this.caregiver,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto do cuidador
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0E0E0),
              ),
              child: caregiver.caregiver.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        caregiver.caregiver.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person,
                                color: Colors.grey, size: 24),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.grey, size: 24),
            ),

            const SizedBox(width: 12),

            // Informações do cuidador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caregiver.caregiver.name ?? 'Nome não informado',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF28323C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caregiver.formattedHourlyRate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        caregiver.isAvailable ? 'Disponível' : 'Indisponível',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              caregiver.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        caregiver.formattedDistance,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ícone de seta
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
