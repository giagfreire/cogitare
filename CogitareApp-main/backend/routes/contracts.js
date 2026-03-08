const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Buscar contrato ativo do responsável
router.get('/active', async (req, res) => {
  try {
    const { responsavel_id } = req.query;

    if (!responsavel_id) {
      return res.status(400).json({
        success: false,
        message: 'ID do responsável é obrigatório'
      });
    }

    // Buscar atendimento ativo
    const contractResult = await db.query(
      `SELECT 
        a.IdAtendimento as id,
        a.IdResponsavel as responsavel_id,
        a.IdCuidador as cuidador_id,
        a.IdIdoso as idoso_id,
        c.Nome as cuidador_nome,
        i.Nome as idoso_nome,
        a.DataInicio as data_inicio,
        a.DataFim as data_fim,
        a.Valor as valor,
        a.Local as local,
        a.Status as status,
        a.ObservacaoExtra as observacoes,
        a.DataCriacao as data_criacao
       FROM atendimento a
       LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
       LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
       WHERE a.IdResponsavel = ? 
       AND a.Status IN ('Agendado', 'Em Andamento', 'Concluído')
       AND DATE(a.DataFim) >= CURDATE()
       ORDER BY a.DataInicio DESC
       LIMIT 1`,
      [responsavel_id]
    );

    if (contractResult.length === 0) {
      return res.json({
        success: true,
        data: null,
        message: 'Nenhum contrato ativo encontrado'
      });
    }

    const contract = contractResult[0];
    
    res.json({
      success: true,
      data: contract
    });

  } catch (error) {
    console.error('Erro ao buscar contrato ativo:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Buscar histórico de contratos
router.get('/history', async (req, res) => {
  try {
    const { responsavel_id } = req.query;

    if (!responsavel_id) {
      return res.status(400).json({
        success: false,
        message: 'ID do responsável é obrigatório'
      });
    }

    const contractsResult = await db.query(
      `SELECT 
        a.IdAtendimento as id,
        a.IdResponsavel as responsavel_id,
        a.IdCuidador as cuidador_id,
        a.IdIdoso as idoso_id,
        c.Nome as cuidador_nome,
        i.Nome as idoso_nome,
        a.DataInicio as data_inicio,
        a.DataFim as data_fim,
        a.Valor as valor,
        a.Local as local,
        a.Status as status,
        a.ObservacaoExtra as observacoes,
        a.DataCriacao as data_criacao
       FROM atendimento a
       LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
       LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
       WHERE a.IdResponsavel = ?
       ORDER BY a.DataInicio DESC`,
      [responsavel_id]
    );

    res.json({
      success: true,
      data: contractsResult
    });

  } catch (error) {
    console.error('Erro ao buscar histórico de contratos:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Criar novo contrato
router.post('/', async (req, res) => {
  try {
    const {
      responsavel_id,
      cuidador_id,
      idoso_id,
      data_inicio,
      data_fim,
      valor,
      local,
      observacoes
    } = req.body;

    // Validar dados obrigatórios
    if (!responsavel_id || !cuidador_id || !idoso_id || !data_inicio || !data_fim || !valor || !local) {
      return res.status(400).json({
        success: false,
        message: 'Dados obrigatórios não fornecidos'
      });
    }

    // Verificar se já existe um contrato ativo
    const existingContract = await db.query(
      `SELECT COUNT(*) as count FROM atendimento 
       WHERE IdResponsavel = ? 
       AND Status IN ('Agendado', 'Em Andamento')
       AND DATE(DataFim) >= CURDATE()`,
      [responsavel_id]
    );

    if (existingContract[0].count > 0) {
      return res.status(400).json({
        success: false,
        message: 'Já existe um contrato ativo para este responsável'
      });
    }

    // Criar novo atendimento
    const result = await db.query(
      `INSERT INTO atendimento 
       (IdResponsavel, IdCuidador, IdIdoso, DataInicio, DataFim, Status, Local, Valor, ObservacaoExtra)
       VALUES (?, ?, ?, ?, ?, 'Agendado', ?, ?, ?)`,
      [responsavel_id, cuidador_id, idoso_id, data_inicio, data_fim, local, valor, observacoes]
    );

    const contractId = result.insertId;

    // Buscar o contrato criado
    const newContract = await db.query(
      `SELECT 
        a.IdAtendimento as id,
        a.IdResponsavel as responsavel_id,
        a.IdCuidador as cuidador_id,
        a.IdIdoso as idoso_id,
        c.Nome as cuidador_nome,
        i.Nome as idoso_nome,
        a.DataInicio as data_inicio,
        a.DataFim as data_fim,
        a.Valor as valor,
        a.Local as local,
        a.Status as status,
        a.ObservacaoExtra as observacoes,
        a.DataCriacao as data_criacao
       FROM atendimento a
       LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
       LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
       WHERE a.IdAtendimento = ?`,
      [contractId]
    );

    res.status(201).json({
      success: true,
      data: newContract[0],
      message: 'Contrato criado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao criar contrato:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Cancelar contrato
router.put('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o contrato existe
    const contract = await db.query(
      'SELECT * FROM atendimento WHERE IdAtendimento = ?',
      [id]
    );

    if (contract.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrato não encontrado'
      });
    }

    // Atualizar status para cancelado
    await db.query(
      'UPDATE atendimento SET Status = ? WHERE IdAtendimento = ?',
      ['Cancelado', id]
    );

    res.json({
      success: true,
      message: 'Contrato cancelado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao cancelar contrato:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
