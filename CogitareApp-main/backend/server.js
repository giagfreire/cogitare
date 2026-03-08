const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Importar rotas
const authRoutes = require('./routes/auth');
const cuidadorRoutes = require('./routes/cuidador');
const idosoRoutes = require('./routes/idoso');
const enderecoRoutes = require('./routes/endereco');
const responsavelRoutes = require('./routes/responsavel');
const nearbyCaregiversRoutes = require('./routes/nearby_caregivers');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS primeiro
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.options('*', cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Muitas tentativas. Tente novamente em alguns minutos.'
  }
});
app.use(limiter);

// Middleware para parsing JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Middleware de logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Rotas
app.use('/api/auth', authRoutes);
app.use('/api/cuidador', cuidadorRoutes);
app.use('/api/idoso', idosoRoutes);
app.use('/api/endereco', enderecoRoutes);
app.use('/api/responsavel', responsavelRoutes);
app.use('/api/nearby-caregivers', nearbyCaregiversRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'API funcionando corretamente',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Rota raiz
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'API Cogitare - Sistema de Cuidados',
    version: '1.0.0'
  });
});

// Tratamento de erros
app.use((err, req, res, next) => {
  console.error('Erro não tratado:', err);
  res.status(500).json({
    success: false,
    message: 'Erro interno do servidor',
    error: err.message
  });
});

// Rotas não encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Rota não encontrada'
  });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📱 API disponível em: http://127.0.0.1:${PORT}`);
  console.log(`🔗 Health check: http://127.0.0.1:${PORT}/api/health`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM recebido. Encerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT recebido. Encerrando servidor...');
  process.exit(0);
});

module.exports = app;
