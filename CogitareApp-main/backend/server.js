const express = require('express');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Importar rotas
const authRoutes = require('./routes/auth');
const cuidadorRoutes = require('./routes/cuidador');
const idosoRoutes = require('./routes/idoso');
const enderecoRoutes = require('./routes/endereco');
const nearbyCaregiversRoutes = require('./routes/nearby_caregivers');
const planosRoutes = require('./routes/planos');
const responsavelRoutes = require('./routes/responsavel');

const app = express();
const PORT = process.env.PORT || 3000;

// =========================
// DESATIVAR CACHE / ETag
// =========================
app.disable('etag');

app.use((req, res, next) => {
  res.setHeader(
    'Cache-Control',
    'no-store, no-cache, must-revalidate, proxy-revalidate'
  );
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  res.setHeader('Surrogate-Control', 'no-store');
  next();
});

// =========================
// CORS / PREFLIGHT FIX
// =========================
app.use((req, res, next) => {
  const origin = req.headers.origin || '*';

  res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Vary', 'Origin');
  res.setHeader(
    'Access-Control-Allow-Methods',
    'GET, POST, PUT, DELETE, OPTIONS'
  );
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization'
  );
  res.setHeader('Access-Control-Max-Age', '86400');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  next();
});

// =========================
// PARSE DO BODY
// =========================
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// =========================
// LOG COMPLETO DA REQUISIÇÃO
// =========================
app.use((req, res, next) => {
  console.log('======================================');
  console.log(`DATA: ${new Date().toISOString()}`);
  console.log(`METHOD: ${req.method}`);
  console.log(`URL: ${req.originalUrl}`);
  console.log('HEADERS:', req.headers);
  console.log('BODY:', req.body);
  console.log('======================================');
  next();
});

// =========================
// RATE LIMIT
// =========================
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Muitas tentativas. Tente novamente em alguns minutos.',
  },
});

// não aplicar rate limit em OPTIONS
app.use('/api/', (req, res, next) => {
  if (req.method === 'OPTIONS') return next();
  return limiter(req, res, next);
});

// =========================
// HEALTH CHECK
// =========================
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API funcionando corretamente',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// =========================
// ROTA RAIZ
// =========================
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API Cogitare - Sistema de Cuidados',
    version: '1.0.0',
  });
});

// =========================
// ROTAS
// =========================
app.use('/api/auth', authRoutes);

app.use(
  '/api/cuidador',
  (req, res, next) => {
    console.log('>>> PASSOU PELO MIDDLEWARE DO CUIDADOR');
    next();
  },
  cuidadorRoutes
);

app.use('/api/idoso', idosoRoutes);
app.use('/api/endereco', enderecoRoutes);
app.use('/api/responsavel', responsavelRoutes);
app.use('/api/nearby-caregivers', nearbyCaregiversRoutes);
app.use('/api/planos', planosRoutes);

// =========================
// ROTA NÃO ENCONTRADA
// =========================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Rota não encontrada',
    path: req.originalUrl,
  });
});

// =========================
// TRATAMENTO DE ERROS
// =========================
app.use((err, req, res, next) => {
  console.error('ERRO NÃO TRATADO NO SERVIDOR:');
  console.error(err);

  if (res.headersSent) {
    return next(err);
  }

  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Erro interno do servidor',
    error: process.env.NODE_ENV === 'development' ? err.stack : err.message,
  });
});

// =========================
// INICIAR SERVIDOR
// =========================
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📱 API disponível em: http://127.0.0.1:${PORT}`);
  console.log(`🔗 Health check: http://127.0.0.1:${PORT}/api/health`);
});

// =========================
// ENCERRAMENTO
// =========================
process.on('SIGTERM', () => {
  console.log('SIGTERM recebido. Encerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT recebido. Encerrando servidor...');
  process.exit(0);
});

module.exports = app;