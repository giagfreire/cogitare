const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

function getResponsavelId(req) {
  return req.user?.id || req.user?.IdResponsavel || req.user?.userId;
}

function normalizarRows(resultado) {
  if (Array.isArray(resultado)) return resultado;
  if (resultado && Array.isArray(resultado.rows)) return resultado.rows;
  return resultado ? [resultado] : [];
}

/* =========================
   CRIAR VAGA (CORRIGIDO)
========================= */

router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const {
      idIdoso,
      titulo,
      descricao,
      cep,
      cidade,
      bairro,
      rua,
      dataServico,
      horaInicio,
      horaFim,
      valor,
      whatsappContato
    } = req.body;

    if (!titulo || !cidade || !dataServico || !horaInicio || !horaFim || !whatsappContato) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando (incluindo WhatsApp)',
      });
    }

    const result = await db.query(
      `
      INSERT INTO vaga
      (
        IdResponsavel,
        IdIdoso,
        Titulo,
        Descricao,
        Cep,
        Cidade,
        Bairro,
        Rua,
        DataServico,
        HoraInicio,
        HoraFim,
        Valor,
        Status,
        WhatsappContato
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Aberta', ?)
      `,
      [
        idResponsavel,
        idIdoso,
        titulo,
        descricao || 'Sem descrição',
        cep,
        cidade,
        bairro,
        rua,
        dataServico,
        horaInicio,
        horaFim,
        valor || 0,
        whatsappContato
      ]
    );

    return res.json({
      success: true,
      message: 'Vaga criada com sucesso',
      data: { idVaga: result.insertId },
    });

  } catch (error) {
    console.error('ERRO CRIAR VAGA:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao criar vaga',
    });
  }
});

/* =========================
   MINHAS VAGAS (COM WHATSAPP)
========================= */

router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const resultado = await db.query(
      `
      SELECT 
        v.*,
        i.Nome AS NomeIdoso,
        COUNT(vc.IdVagaCuidador) AS TotalInteressados
      FROM vaga v
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      LEFT JOIN vagacuidador vc ON vc.IdVaga = v.IdVaga
      WHERE v.IdResponsavel = ?
      GROUP BY v.IdVaga
      ORDER BY v.IdVaga DESC
      `,
      [idResponsavel]
    );

    return res.json({
      success: true,
      data: normalizarRows(resultado),
    });

  } catch (error) {
    console.error('ERRO MINHAS VAGAS:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao listar vagas',
    });
  }
});

/* =========================
   EXCLUIR VAGA (FIX)
========================= */

router.delete('/vaga/:id', authenticateToken, async (req, res) => {
  try {
    const idVaga = req.params.id;
    const idResponsavel = getResponsavelId(req);

    await db.query(
      `DELETE FROM vagacuidador WHERE IdVaga = ?`,
      [idVaga]
    );

    await db.query(
      `DELETE FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?`,
      [idVaga, idResponsavel]
    );

    return res.json({
      success: true,
      message: 'Vaga excluída com sucesso',
    });

  } catch (error) {
    console.error('ERRO EXCLUIR VAGA:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao excluir vaga',
    });
  }
});

module.exports = router;