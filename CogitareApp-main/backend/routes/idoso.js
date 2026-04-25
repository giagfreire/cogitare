const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Criar idoso do responsável logado
router.post('/', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem cadastrar idosos',
      });
    }

    const {
      IdMobilidade,
      IdNivelAutonomia,
      Nome,
      DataNascimento,
      Sexo,
      CuidadosMedicos,
      DescricaoExtra,
      UsaMedicacao,
      MedicacaoDetalhes,
      PrecisaBanho,
      BanhoDetalhes,
      PrecisaAlimentacao,
      AlimentacaoDetalhes,
      PrecisaAcompanhamento,
      AcompanhamentoDetalhes,
    } = req.body;

    if (!Nome || !DataNascimento || !Sexo || !IdMobilidade || !IdNivelAutonomia) {
      return res.status(400).json({
        success: false,
        message: 'Preencha nome, nascimento, sexo, mobilidade e autonomia.',
      });
    }

    const result = await db.query(
      `INSERT INTO idoso
      (
        IdResponsavel, IdMobilidade, IdNivelAutonomia, Nome, DataNascimento,
        Sexo, CuidadosMedicos, DescricaoExtra, FotoUrl,
        UsaMedicacao, MedicacaoDetalhes,
        PrecisaBanho, BanhoDetalhes,
        PrecisaAlimentacao, AlimentacaoDetalhes,
        PrecisaAcompanhamento, AcompanhamentoDetalhes
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        IdMobilidade,
        IdNivelAutonomia,
        Nome,
        DataNascimento,
        Sexo,
        CuidadosMedicos || null,
        DescricaoExtra || null,
        UsaMedicacao || 'Não',
        UsaMedicacao === 'Sim' ? MedicacaoDetalhes || null : null,
        PrecisaBanho || 'Não',
        PrecisaBanho === 'Sim' ? BanhoDetalhes || null : null,
        PrecisaAlimentacao || 'Não',
        PrecisaAlimentacao === 'Sim' ? AlimentacaoDetalhes || null : null,
        PrecisaAcompanhamento || 'Não',
        PrecisaAcompanhamento === 'Sim' ? AcompanhamentoDetalhes || null : null,
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Perfil do idoso cadastrado com sucesso',
      data: {
        IdIdoso: result.insertId,
      },
    });
  } catch (error) {
    console.error('Erro ao criar idoso:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

// Listar idosos do responsável logado
router.get('/meus', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem listar idosos',
      });
    }

    const idosos = await db.query(
      `SELECT
        i.*,
        m.Descricao AS MobilidadeDesc,
        na.Descricao AS AutonomiaDesc
      FROM idoso i
      LEFT JOIN mobilidade m ON i.IdMobilidade = m.IdMobilidade
      LEFT JOIN nivelautonomia na ON i.IdNivelAutonomia = na.IdNivelAutonomia
      WHERE i.IdResponsavel = ?
      ORDER BY i.IdIdoso DESC`,
      [req.user.id]
    );

    return res.json({
      success: true,
      data: idosos,
    });
  } catch (error) {
    console.error('Erro ao listar idosos:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

// Buscar idoso por ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem acessar idosos',
      });
    }

    const { id } = req.params;

    const idosos = await db.query(
      `SELECT
        i.*,
        m.Descricao AS MobilidadeDesc,
        na.Descricao AS AutonomiaDesc
      FROM idoso i
      LEFT JOIN mobilidade m ON i.IdMobilidade = m.IdMobilidade
      LEFT JOIN nivelautonomia na ON i.IdNivelAutonomia = na.IdNivelAutonomia
      WHERE i.IdIdoso = ?
        AND i.IdResponsavel = ?
      LIMIT 1`,
      [id, req.user.id]
    );

    if (!idosos || idosos.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Idoso não encontrado',
      });
    }

    return res.json({
      success: true,
      data: idosos[0],
    });
  } catch (error) {
    console.error('Erro ao buscar idoso:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

// Atualizar idoso
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem editar idosos',
      });
    }

    const { id } = req.params;

    const {
      IdMobilidade,
      IdNivelAutonomia,
      Nome,
      DataNascimento,
      Sexo,
      CuidadosMedicos,
      DescricaoExtra,
      UsaMedicacao,
      MedicacaoDetalhes,
      PrecisaBanho,
      BanhoDetalhes,
      PrecisaAlimentacao,
      AlimentacaoDetalhes,
      PrecisaAcompanhamento,
      AcompanhamentoDetalhes,
    } = req.body;

    if (!Nome || !DataNascimento || !Sexo || !IdMobilidade || !IdNivelAutonomia) {
      return res.status(400).json({
        success: false,
        message: 'Preencha nome, nascimento, sexo, mobilidade e autonomia.',
      });
    }

    const idosos = await db.query(
      'SELECT IdIdoso FROM idoso WHERE IdIdoso = ? AND IdResponsavel = ? LIMIT 1',
      [id, req.user.id]
    );

    if (!idosos || idosos.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Idoso não encontrado',
      });
    }

    await db.query(
      `UPDATE idoso
       SET
        IdMobilidade = ?,
        IdNivelAutonomia = ?,
        Nome = ?,
        DataNascimento = ?,
        Sexo = ?,
        CuidadosMedicos = ?,
        DescricaoExtra = ?,
        UsaMedicacao = ?,
        MedicacaoDetalhes = ?,
        PrecisaBanho = ?,
        BanhoDetalhes = ?,
        PrecisaAlimentacao = ?,
        AlimentacaoDetalhes = ?,
        PrecisaAcompanhamento = ?,
        AcompanhamentoDetalhes = ?
       WHERE IdIdoso = ?
         AND IdResponsavel = ?`,
      [
        IdMobilidade,
        IdNivelAutonomia,
        Nome,
        DataNascimento,
        Sexo,
        CuidadosMedicos || null,
        DescricaoExtra || null,
        UsaMedicacao || 'Não',
        UsaMedicacao === 'Sim' ? MedicacaoDetalhes || null : null,
        PrecisaBanho || 'Não',
        PrecisaBanho === 'Sim' ? BanhoDetalhes || null : null,
        PrecisaAlimentacao || 'Não',
        PrecisaAlimentacao === 'Sim' ? AlimentacaoDetalhes || null : null,
        PrecisaAcompanhamento || 'Não',
        PrecisaAcompanhamento === 'Sim' ? AcompanhamentoDetalhes || null : null,
        id,
        req.user.id,
      ]
    );

    return res.json({
      success: true,
      message: 'Perfil do idoso atualizado com sucesso',
    });
  } catch (error) {
    console.error('Erro ao atualizar idoso:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

module.exports = router;