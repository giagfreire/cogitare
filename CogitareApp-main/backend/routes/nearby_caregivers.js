const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Simula coordenadas para endereços (em um app real, isso viria de uma API de geocoding)
const mockCoordinates = {
  // Brasil
  'São Paulo': { lat: -23.5505, lon: -46.6333 },
  'Rio de Janeiro': { lat: -22.9068, lon: -43.1729 },
  'Belo Horizonte': { lat: -19.9167, lon: -43.9345 },
  'Salvador': { lat: -12.9714, lon: -38.5014 },
  'Brasília': { lat: -15.7801, lon: -47.9292 },
  'Fortaleza': { lat: -3.7172, lon: -38.5434 },
  'Manaus': { lat: -3.1190, lon: -60.0217 },
  'Curitiba': { lat: -25.4244, lon: -49.2654 },
  'Recife': { lat: -8.0476, lon: -34.8770 },
  'Porto Alegre': { lat: -30.0346, lon: -51.2177 },
  'Brasil': { lat: -14.2350, lon: -51.9253 },
  
  // Estados Unidos
  'New York': { lat: 40.7128, lon: -74.0060 },
  'Los Angeles': { lat: 34.0522, lon: -118.2437 },
  'Chicago': { lat: 41.8781, lon: -87.6298 },
  'Houston': { lat: 29.7604, lon: -95.3698 },
  'Phoenix': { lat: 33.4484, lon: -112.0740 },
  'Philadelphia': { lat: 39.9526, lon: -75.1652 },
  'San Antonio': { lat: 29.4241, lon: -98.4936 },
  'San Diego': { lat: 32.7157, lon: -117.1611 },
  'Dallas': { lat: 32.7767, lon: -96.7970 },
  'San Jose': { lat: 37.3382, lon: -121.8863 },
  'Estados Unidos': { lat: 39.8283, lon: -98.5795 },
  
  // Europa
  'Londres': { lat: 51.5074, lon: -0.1278 },
  'Paris': { lat: 48.8566, lon: 2.3522 },
  'Berlim': { lat: 52.5200, lon: 13.4050 },
  'Madrid': { lat: 40.4168, lon: -3.7038 },
  'Roma': { lat: 41.9028, lon: 12.4964 },
  'Amsterdam': { lat: 52.3676, lon: 4.9041 },
  'Viena': { lat: 48.2082, lon: 16.3738 },
  'Praga': { lat: 50.0755, lon: 14.4378 },
  'Barcelona': { lat: 41.3851, lon: 2.1734 },
  'Milão': { lat: 45.4642, lon: 9.1900 },
  'Europa': { lat: 54.5260, lon: 15.2551 },
  
  // Ásia
  'Tóquio': { lat: 35.6762, lon: 139.6503 },
  'Pequim': { lat: 39.9042, lon: 116.4074 },
  'Xangai': { lat: 31.2304, lon: 121.4737 },
  'Seul': { lat: 37.5665, lon: 126.9780 },
  'Hong Kong': { lat: 22.3193, lon: 114.1694 },
  'Singapura': { lat: 1.3521, lon: 103.8198 },
  'Bangkok': { lat: 13.7563, lon: 100.5018 },
  'Mumbai': { lat: 19.0760, lon: 72.8777 },
  'Delhi': { lat: 28.7041, lon: 77.1025 },
  'Jakarta': { lat: -6.2088, lon: 106.8456 },
  'Ásia': { lat: 34.0479, lon: 100.6197 },
  
  // América do Sul
  'Buenos Aires': { lat: -34.6118, lon: -58.3960 },
  'Lima': { lat: -12.0464, lon: -77.0428 },
  'Bogotá': { lat: 4.7110, lon: -74.0721 },
  'Santiago': { lat: -33.4489, lon: -70.6693 },
  'Caracas': { lat: 10.4806, lon: -66.9036 },
  'Quito': { lat: -0.1807, lon: -78.4678 },
  'La Paz': { lat: -16.2902, lon: -63.5887 },
  'Montevideo': { lat: -34.9011, lon: -56.1645 },
  'Asunción': { lat: -25.2637, lon: -57.5759 },
  'Georgetown': { lat: 6.8013, lon: -58.1551 },
  'América do Sul': { lat: -14.2350, lon: -51.9253 },
  
  // América do Norte
  'Toronto': { lat: 43.6532, lon: -79.3832 },
  'Vancouver': { lat: 49.2827, lon: -123.1207 },
  'Montreal': { lat: 45.5017, lon: -73.5673 },
  'Calgary': { lat: 51.0447, lon: -114.0719 },
  'Ottawa': { lat: 45.4215, lon: -75.6972 },
  'Cidade do México': { lat: 19.4326, lon: -99.1332 },
  'Guadalajara': { lat: 20.6597, lon: -103.3496 },
  'Puebla': { lat: 19.0414, lon: -98.2063 },
  'Tijuana': { lat: 32.5149, lon: -117.0382 },
  'León': { lat: 21.1253, lon: -101.6860 },
  'América do Norte': { lat: 54.5260, lon: -105.2551 },
  
  // África
  'Cairo': { lat: 30.0444, lon: 31.2357 },
  'Lagos': { lat: 6.5244, lon: 3.3792 },
  'Cidade do Cabo': { lat: -33.9249, lon: 18.4241 },
  'Joanesburgo': { lat: -26.2041, lon: 28.0473 },
  'Casablanca': { lat: 33.5731, lon: -7.5898 },
  'Nairobi': { lat: -1.2921, lon: 36.8219 },
  'Adis Abeba': { lat: 9.1450, lon: 38.7667 },
  'Túnis': { lat: 36.8065, lon: 10.1815 },
  'Argel': { lat: 36.7372, lon: 3.0869 },
  'Dakar': { lat: 14.6928, lon: -17.4467 },
  'África': { lat: 8.7832, lon: 34.5085 },
  
  // Oceania
  'Sydney': { lat: -33.8688, lon: 151.2093 },
  'Melbourne': { lat: -37.8136, lon: 144.9631 },
  'Brisbane': { lat: -27.4698, lon: 153.0251 },
  'Perth': { lat: -31.9505, lon: 115.8605 },
  'Adelaide': { lat: -34.9285, lon: 138.6007 },
  'Auckland': { lat: -36.8485, lon: 174.7633 },
  'Wellington': { lat: -41.2924, lon: 174.7787 },
  'Christchurch': { lat: -43.5321, lon: 172.6362 },
  'Dunedin': { lat: -45.8788, lon: 170.5028 },
  'Hamilton': { lat: -37.7870, lon: 175.2793 },
  'Oceania': { lat: -25.2744, lon: 133.7751 },
};

// Função para calcular distância usando fórmula de Haversine
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Raio da Terra em quilômetros
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Função para obter coordenadas baseadas na cidade
function getCoordinatesForCity(city) {
  const coords = mockCoordinates[city];
  if (coords) {
    // Adiciona uma variação consistente baseada no nome da cidade
    const hash = city.split('').reduce((a, b) => {
      a = ((a << 5) - a) + b.charCodeAt(0);
      return a & a;
    }, 0);
    const variation = (Math.abs(hash) % 100) / 1000; // Variação pequena e consistente
    return {
      lat: coords.lat + (variation - 0.05),
      lon: coords.lon + (variation - 0.05)
    };
  }
  // Coordenadas padrão para São Paulo se cidade não encontrada
  return { lat: -23.5505, lon: -46.6333 };
}

// Função para gerar taxa por hora baseada no ID do cuidador (consistente)
function generateHourlyRate(caregiverId) {
  // Usar o ID do cuidador para gerar uma taxa consistente
  const baseRate = 20 + (caregiverId * 3.5); // Taxa base baseada no ID
  const variation = (caregiverId % 10) * 2; // Variação pequena
  return Math.round((baseRate + variation) * 100) / 100;
}

// Função para verificar disponibilidade estável
async function isCaregiverAvailable(caregiverId, db) {
  try {
    // Verificar se o cuidador tem agendamentos ativos hoje
    const today = new Date().toISOString().split('T')[0];
    
    const activeAppointments = await db.query(
      `SELECT COUNT(*) as count FROM atendimento 
       WHERE IdCuidador = ? 
       AND DATE(DataInicio) = ? 
       AND Status IN ('Agendado', 'Em Andamento')`,
      [caregiverId, today]
    );
    
    // Se tem agendamentos hoje, considera indisponível
    const hasAppointments = activeAppointments[0].count > 0;
    
    if (hasAppointments) {
      return false; // Indisponível se tem agendamentos
    }
    
    // Por enquanto, considera todos disponíveis se não tem agendamentos
    // Isso garante consistência na lista
    return true;
    
  } catch (error) {
    console.error('Erro ao verificar disponibilidade:', error);
    // Em caso de erro, considera disponível para não perder cuidadores
    return true;
  }
}

// Função para obter o dia da semana atual
function getCurrentDayOfWeek() {
  const days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  return days[new Date().getDay()];
}

// Buscar cuidadores próximos
router.get('/nearby', async (req, res) => {
  try {
    const { 
      guardian_id, 
      max_distance = 999999, // Distância muito alta para não limitar
      limit = 10,
      min_hourly_rate,
      max_hourly_rate,
      only_available
    } = req.query;

    if (!guardian_id) {
      return res.status(400).json({
        success: false,
        message: 'ID do responsável é obrigatório'
      });
    }

    // 1. Buscar endereço do responsável
    const guardianResult = await db.query(
      `SELECT e.Cidade as cidade, e.Bairro as bairro, e.Rua as logradouro, 
              e.Numero as numero, e.Complemento as complemento, e.Cep as cep
       FROM responsavel r 
       LEFT JOIN endereco e ON r.IdEndereco = e.IdEndereco 
       WHERE r.IdResponsavel = ?`,
      [guardian_id]
    );

    if (guardianResult.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado'
      });
    }

    const guardianAddress = guardianResult[0];
    const guardianCoords = getCoordinatesForCity(guardianAddress.cidade);

    // 2. Buscar todos os cuidadores com seus endereços
    const caregiversResult = await db.query(
      `SELECT c.IdCuidador as id, c.Nome as nome, c.Email as email, c.Telefone as telefone, c.Cpf as cpf, c.DataNascimento as data_nascimento,
              c.FotoUrl as foto_url, c.Biografia as biografia, c.Fumante as fumante, c.TemFilhos as tem_filhos, 
              c.PossuiCNH as possui_cnh, c.TemCarro as tem_carro,
              e.IdEndereco as endereco_id, e.Cidade as cidade, e.Bairro as bairro, e.Rua as logradouro, 
              e.Numero as numero, e.Complemento as complemento, e.Cep as cep
       FROM cuidador c 
       LEFT JOIN endereco e ON c.IdEndereco = e.IdEndereco
       ORDER BY c.IdCuidador ASC`
    );

    // 3. Calcular distâncias e filtrar
    const allCaregivers = [];

    for (const caregiver of caregiversResult) {
      if (!caregiver.cidade) continue; // Pular se não tem endereço

      const caregiverCoords = getCoordinatesForCity(caregiver.cidade);
      const distance = calculateDistance(
        guardianCoords.lat,
        guardianCoords.lon,
        caregiverCoords.lat,
        caregiverCoords.lon
      );

      const hourlyRate = generateHourlyRate(caregiver.id);
      const isAvailable = await isCaregiverAvailable(caregiver.id, db);

      // Aplicar filtros adicionais
      if (min_hourly_rate && hourlyRate < min_hourly_rate) continue;
      if (max_hourly_rate && hourlyRate > max_hourly_rate) continue;
      if (only_available === 'true' && !isAvailable) continue;

      allCaregivers.push({
        caregiver: {
          id: caregiver.id,
          nome: caregiver.nome,
          email: caregiver.email,
          telefone: caregiver.telefone,
          cpf: caregiver.cpf,
          data_nascimento: caregiver.data_nascimento,
          foto_url: caregiver.foto_url,
          biografia: caregiver.biografia,
          fumante: caregiver.fumante,
          tem_filhos: caregiver.tem_filhos,
          possui_cnh: caregiver.possui_cnh,
          tem_carro: caregiver.tem_carro
        },
        address: {
          id: caregiver.id,
          cidade: caregiver.cidade,
          bairro: caregiver.bairro,
          logradouro: caregiver.logradouro,
          numero: caregiver.numero,
          complemento: caregiver.complemento,
          cep: caregiver.cep
        },
        distance: Math.round(distance * 100) / 100,
        hourly_rate: hourlyRate,
        is_available: isAvailable
      });
    }

    // 4. Ordenar por distância e limitar resultados
    allCaregivers.sort((a, b) => a.distance - b.distance);
    
    // Se não há cuidadores próximos, retorna pelo menos o mais próximo disponível
    const nearbyCaregivers = allCaregivers.filter(c => c.distance <= max_distance);
    const limitedResults = nearbyCaregivers.length > 0 
      ? nearbyCaregivers.slice(0, limit)
      : allCaregivers.slice(0, Math.max(1, limit)); // Garante pelo menos 1 resultado

    res.json({
      success: true,
      data: limitedResults,
      total: limitedResults.length,
      filters: {
        max_distance: max_distance,
        limit: limit,
        min_hourly_rate,
        max_hourly_rate,
        only_available
      }
    });

  } catch (error) {
    console.error('Erro ao buscar cuidadores próximos:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Buscar cuidadores próximos por coordenadas
router.get('/nearby/coordinates', async (req, res) => {
  try {
    const { 
      latitude, 
      longitude, 
      max_distance = 999999, // Distância muito alta para não limitar
      limit = 10,
      min_hourly_rate,
      max_hourly_rate,
      only_available
    } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude e longitude são obrigatórios'
      });
    }

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);

    // Buscar todos os cuidadores com seus endereços
    const caregiversResult = await db.query(
      `SELECT c.IdCuidador as id, c.Nome as nome, c.Email as email, c.Telefone as telefone, c.Cpf as cpf, c.DataNascimento as data_nascimento,
              c.FotoUrl as foto_url, c.Biografia as biografia, c.Fumante as fumante, c.TemFilhos as tem_filhos, 
              c.PossuiCNH as possui_cnh, c.TemCarro as tem_carro,
              e.IdEndereco as endereco_id, e.Cidade as cidade, e.Bairro as bairro, e.Rua as logradouro, 
              e.Numero as numero, e.Complemento as complemento, e.Cep as cep
       FROM cuidador c 
       LEFT JOIN endereco e ON c.IdEndereco = e.IdEndereco
       ORDER BY c.IdCuidador ASC`
    );

    // Calcular distâncias e filtrar
    const allCaregivers = [];

    for (const caregiver of caregiversResult) {
      if (!caregiver.cidade) continue;

      const caregiverCoords = getCoordinatesForCity(caregiver.cidade);
      const distance = calculateDistance(
        lat,
        lon,
        caregiverCoords.lat,
        caregiverCoords.lon
      );

      const hourlyRate = generateHourlyRate(caregiver.id);
      const isAvailable = await isCaregiverAvailable(caregiver.id, db);

      // Aplicar filtros adicionais
      if (min_hourly_rate && hourlyRate < min_hourly_rate) continue;
      if (max_hourly_rate && hourlyRate > max_hourly_rate) continue;
      if (only_available === 'true' && !isAvailable) continue;

      allCaregivers.push({
        caregiver: {
          id: caregiver.id,
          nome: caregiver.nome,
          email: caregiver.email,
          telefone: caregiver.telefone,
          cpf: caregiver.cpf,
          data_nascimento: caregiver.data_nascimento,
          foto_url: caregiver.foto_url,
          biografia: caregiver.biografia,
          fumante: caregiver.fumante,
          tem_filhos: caregiver.tem_filhos,
          possui_cnh: caregiver.possui_cnh,
          tem_carro: caregiver.tem_carro
        },
        address: {
          id: caregiver.id,
          cidade: caregiver.cidade,
          bairro: caregiver.bairro,
          logradouro: caregiver.logradouro,
          numero: caregiver.numero,
          complemento: caregiver.complemento,
          cep: caregiver.cep
        },
        distance: Math.round(distance * 100) / 100,
        hourly_rate: hourlyRate,
        is_available: isAvailable
      });
    }

    // Ordenar por distância e limitar resultados
    allCaregivers.sort((a, b) => a.distance - b.distance);
    
    // Se não há cuidadores próximos, retorna pelo menos o mais próximo disponível
    const nearbyCaregivers = allCaregivers.filter(c => c.distance <= max_distance);
    const limitedResults = nearbyCaregivers.length > 0 
      ? nearbyCaregivers.slice(0, limit)
      : allCaregivers.slice(0, Math.max(1, limit)); // Garante pelo menos 1 resultado

    res.json({
      success: true,
      data: limitedResults,
      total: limitedResults.length,
      filters: {
        latitude: lat,
        longitude: lon,
        max_distance: max_distance,
        limit: limit,
        min_hourly_rate,
        max_hourly_rate,
        only_available
      }
    });

  } catch (error) {
    console.error('Erro ao buscar cuidadores próximos por coordenadas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
