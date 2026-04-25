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
   PERFIL
========================= */

router.get('/perfil', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const resultado = await db.query(
      `
      SELECT 
        IdResponsavel,
        Nome,
        Email,
        Telefone,
        Cpf,
        DataNascimento,
        FotoUrl,
        Cep,
        Cidade,
        Bairro,
        Rua,
        Numero,
        Estado,
        Complemento,
        ContatoWhatsapp,
        ContatoTelefone,
        ContatoEmail,
        PreferenciaContato
      FROM responsavel
      WHERE IdResponsavel = ?
      LIMIT 1
      `,
      [idResponsavel]
    );

    const rows = normalizarRows(resultado);

    if (!rows.length) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado.',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar perfil.',
    });
  }
});

router.put('/perfil', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const {
      nome,
      email,
      telefone,
      dataNascimento,
      fotoUrl,
      cep,
      cidade,
      bairro,
      rua,
      numero,
      estado,
      complemento,
      contatoWhatsapp,
      contatoTelefone,
      contatoEmail,
      preferenciaContato,
    } = req.body;

    await db.query(
      `
      UPDATE responsavel SET
        Nome = ?,
        Email = ?,
        Telefone = ?,
        DataNascimento = ?,
        FotoUrl = ?,
        Cep = ?,
        Cidade = ?,
        Bairro = ?,
        Rua = ?,
        Numero = ?,
        Estado = ?,
        Complemento = ?,
        ContatoWhatsapp = ?,
        ContatoTelefone = ?,
        ContatoEmail = ?,
        PreferenciaContato = ?
      WHERE IdResponsavel = ?
      `,
      [
        nome,
        email,
        telefone,
        dataNascimento || null,
        fotoUrl || null,
        cep || null,
        cidade || null,
        bairro || null,
        rua || null,
        numero || null,
        estado || null,
        complemento || null,
        contatoWhatsapp || null,
        contatoTelefone || null,
        contatoEmail || null,
        preferenciaContato || null,
        idResponsavel,
      ]
    );

    return res.json({
      success: true,
      message: 'Perfil atualizado com sucesso',
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar perfil',
    });
  }
});

/* =========================
   VAGAS
========================= */

router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const {
      idIdoso,
      titulo,
      cep,
      cidade,
      bairro,
      rua,
      dataServico,
      horaInicio,
      horaFim,
    } = req.body;

    const result = await db.query(
      `
      INSERT INTO vaga
      (IdResponsavel, IdIdoso, Titulo, Descricao, Cep, Cidade, Bairro, Rua, DataServico, HoraInicio, HoraFim, Valor, Status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        idResponsavel,
        idIdoso,
        titulo,
        'Valor a combinar',
        cep,
        cidade,
        bairro,
        rua,
        dataServico,
        horaInicio,
        horaFim,
        0,
        'Aberta',
      ]
    );

    return res.json({
      success: true,
      data: { idVaga: result.insertId },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao criar vaga',
    });
  }
});

router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const resultado = await db.query(
      `
      SELECT 
        v.*,
        i.Nome AS NomeIdoso,
        COUNT(iv.IdInteresse) AS interessados
      FROM vaga v
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      LEFT JOIN interesse_vaga iv ON iv.IdVaga = v.IdVaga
      WHERE v.IdResponsavel = ?
      GROUP BY v.IdVaga
      ORDER BY v.DataCriacao DESC
      `,
      [idResponsavel]
    );

    return res.json({
      success: true,
      data: normalizarRows(resultado),
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao listar minhas vagas',
    });
  }
});

/* =========================
   CONTATO PARA CUIDADOR
========================= */

router.get('/contato/:idResponsavel', async (req, res) => {
  try {
    const { idResponsavel } = req.params;

    const resultado = await db.query(
      `
      SELECT 
        Nome,
        ContatoWhatsapp,
        ContatoTelefone,
        ContatoEmail,
        PreferenciaContato
      FROM responsavel
      WHERE IdResponsavel = ?
      LIMIT 1
      `,
      [idResponsavel]
    );

    const rows = normalizarRows(resultado);

    if (!rows.length) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar contato',
    });
  }
});

module.exports = router;