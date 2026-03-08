const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET - Buscar estatísticas do cuidador
router.get('/cuidador/:cuidadorId/estatisticas', authenticateToken, async (req, res) => {
  try {
    const { cuidadorId } = req.params;

    // Propostas Pendentes: Atendimentos onde Status != 'Concluído' e Status != 'Cancelado'
    // e DataInicio > hoje (atendimentos futuros ou pendentes)
    const propostasPendentes = await db.query(
      `SELECT COUNT(*) as count 
       FROM atendimento 
       WHERE IdCuidador = ? 
       AND Status != 'Concluído' 
       AND Status != 'Cancelado'
       AND (Status IS NULL OR Status = '' OR Status = 'Pendente' OR Status = 'Aguardando')`,
      [cuidadorId]
    );

    // Serviços Ativos: Atendimentos em andamento (Status = 'Em Andamento' ou DataInicio <= hoje e DataFim >= hoje)
    const servicosAtivos = await db.query(
      `SELECT COUNT(*) as count 
       FROM atendimento 
       WHERE IdCuidador = ? 
       AND Status != 'Concluído' 
       AND Status != 'Cancelado'
       AND (Status = 'Em Andamento' OR Status = 'Aceito' OR (DataInicio <= NOW() AND DataFim >= NOW()))`,
      [cuidadorId]
    );

    // Concluídos: Atendimentos com Status = 'Concluído'
    const concluidos = await db.query(
      `SELECT COUNT(*) as count 
       FROM atendimento 
       WHERE IdCuidador = ? 
       AND Status = 'Concluído'`,
      [cuidadorId]
    );

    res.json({
      success: true,
      data: {
        propostasPendentes: propostasPendentes[0]?.count || 0,
        servicosAtivos: servicosAtivos[0]?.count || 0,
        concluidos: concluidos[0]?.count || 0,
      },
    });

  } catch (error) {
    console.error('Erro ao buscar estatísticas do cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
    });
  }
});

// GET - Buscar próximo atendimento do cuidador
router.get('/cuidador/:cuidadorId/proximo', authenticateToken, async (req, res) => {
  try {
    const { cuidadorId } = req.params;

    // Buscar o atendimento mais próximo em data que não seja 'Pendente' nem 'Concluído'
    const atendimentos = await db.query(
      `SELECT 
        a.IdAtendimento as id,
        a.DataInicio as data_inicio,
        a.DataFim as data_fim,
        a.Local as local,
        a.Status as status,
        a.Valor as valor,
        a.ObservacaoExtra as observacao,
        r.Nome as nome_responsavel,
        i.Nome as nome_idoso
       FROM atendimento a
       LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
       LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
       WHERE a.IdCuidador = ?
       AND a.Status != 'Pendente'
       AND a.Status != 'Concluído'
       AND a.Status != 'Cancelado'
       AND a.DataInicio >= NOW()
       ORDER BY a.DataInicio ASC
       LIMIT 1`,
      [cuidadorId]
    );

    if (atendimentos.length === 0) {
      return res.json({
        success: true,
        data: null,
      });
    }

    res.json({
      success: true,
      data: atendimentos[0],
    });

  } catch (error) {
    console.error('Erro ao buscar próximo atendimento:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
    });
  }
});

// GET - Listar atendimentos do cuidador
router.get('/cuidador/:cuidadorId', authenticateToken, async (req, res) => {
  try {
    const { cuidadorId } = req.params;

    const atendimentos = await db.query(
      `SELECT 
        a.IdAtendimento as id,
        a.DataInicio as data_inicio,
        a.DataFim as data_fim,
        a.Local as local,
        a.Status as status,
        a.Valor as valor,
        a.ObservacaoExtra as observacao,
        r.Nome as nome_responsavel,
        i.Nome as nome_idoso
       FROM atendimento a
       LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
       LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
       WHERE a.IdCuidador = ?
       ORDER BY a.DataInicio DESC`,
      [cuidadorId]
    );

    res.json({
      success: true,
      data: atendimentos,
    });

  } catch (error) {
    console.error('Erro ao listar atendimentos do cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
    });
  }
});

module.exports = router;

