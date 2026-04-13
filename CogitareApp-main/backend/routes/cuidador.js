const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

function getCuidadorIdFromRequest(req) {
  return (
    req.user?.id ||
    req.user?.IdCuidador ||
    req.user?.idCuidador ||
    req.user?.cuidadorId ||
    null
  );
}

/**
 * CADASTRO
 */
router.post('/cadastro', async (req, res) => {
  try {
    const {
      nome,
      email,
      senha,
      telefone,
      cpf,
      dataNascimento,
      cidade,
      bairro,
      rua,
      numero,
      complemento,
      cep,
      fumante,
      temFilhos,
      possuiCnh,
      temCarro,
      biografia,
      valorHora,
      fotoUrl,
    } = req.body;

    if (!nome || !email || !senha || !telefone || !cpf) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios não preenchidos.',
      });
    }

    const [emailExiste] = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Email = ? LIMIT 1',
      [email]
    );

    if (emailExiste.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'E-mail já cadastrado.',
      });
    }

    const [cpfExiste] = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Cpf = ? LIMIT 1',
      [cpf]
    );

    if (cpfExiste.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado.',
      });
    }

    let idEndereco = null;

    if (cidade || bairro || rua || numero || cep) {
      const [end] = await db.query(
        `INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [cidade, bairro, rua, numero, complemento, cep]
      );

      idEndereco = end.insertId;
    }

    const senhaHash = await bcrypt.hash(senha, 10);

    const [result] = await db.query(
      `INSERT INTO cuidador
       (IdEndereco, Cpf, Nome, Email, Telefone, Senha, DataNascimento,
        FotoUrl, Biografia, Fumante, TemFilhos, PossuiCNH, TemCarro, ValorHora, UsosPlano)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`,
      [
        idEndereco,
        cpf,
        nome,
        email,
        telefone,
        senhaHash,
        dataNascimento || null,
        fotoUrl || null,
        biografia || null,
        fumante || 'Não',
        temFilhos || 'Não',
        possuiCnh || 'Não',
        temCarro || 'Não',
        valorHora || null,
      ]
    );

    return res.json({
      success: true,
      data: {
        idCuidador: result.insertId,
      },
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: e.message });
  }
});

/**
 * VAGAS ABERTAS
 */
router.get('/vagas-abertas', authenticateToken, async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        v.IdVaga,
        v.Titulo,
        v.Descricao,
        v.Cidade,
        v.DataServico,
        v.HoraInicio,
        v.HoraFim,
        v.Valor,
        r.Nome AS NomeResponsavel,
        r.Email AS EmailResponsavel,
        r.Telefone AS TelefoneResponsavel
      FROM vaga v
      JOIN responsavel r ON r.IdResponsavel = v.IdResponsavel
      WHERE v.Status = 'Aberta'
      ORDER BY v.IdVaga DESC
    `);

    return res.json(rows);
  } catch (e) {
    return res.status(500).json({ success: false });
  }
});

/**
 * ACEITAR VAGA
 */
router.post('/aceitar-vaga', authenticateToken, async (req, res) => {
  try {
    const idCuidador = getCuidadorIdFromRequest(req);
    const { idVaga } = req.body;

    if (!idCuidador) {
      return res.status(401).json({ success: false });
    }

    const [cuidador] = await db.query(
      'SELECT UsosPlano FROM cuidador WHERE IdCuidador = ?',
      [idCuidador]
    );

    const usos = cuidador[0]?.UsosPlano || 0;
    const limite = 5;

    if (usos >= limite) {
      return res.json({
        success: false,
        message: 'Limite atingido. Faça upgrade para Premium.',
      });
    }

    await db.query(
      `INSERT INTO vagacuidador (IdVaga, IdCuidador, DataAceite)
       VALUES (?, ?, NOW())`,
      [idVaga, idCuidador]
    );

    await db.query(
      `UPDATE cuidador SET UsosPlano = UsosPlano + 1 WHERE IdCuidador = ?`,
      [idCuidador]
    );

    return res.json({
      success: true,
      message: 'Vaga aceita com sucesso',
    });
  } catch (e) {
    return res.status(500).json({ success: false });
  }
});

/**
 * STATUS PLANO
 */
router.get('/status-plano', authenticateToken, async (req, res) => {
  try {
    const id = getCuidadorIdFromRequest(req);

    const [rows] = await db.query(
      `SELECT UsosPlano FROM cuidador WHERE IdCuidador = ?`,
      [id]
    );

    const usados = rows[0]?.UsosPlano || 0;

    return res.json({
      success: true,
      data: {
        PlanoAtual: usados >= 5 ? 'Premium' : 'Basico',
        UsosPlano: usados,
        LimitePlano: 5,
      },
    });
  } catch (e) {
    return res.status(500).json({ success: false });
  }
});

/**
 * MINHAS VAGAS
 */
router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const id = getCuidadorIdFromRequest(req);

    const [rows] = await db.query(`
      SELECT
        v.IdVaga,
        v.Titulo,
        v.Descricao,
        v.Cidade,
        v.DataServico,
        v.Valor,
        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel,
        r.Email AS EmailResponsavel
      FROM vagacuidador vc
      JOIN vaga v ON v.IdVaga = vc.IdVaga
      JOIN responsavel r ON r.IdResponsavel = v.IdResponsavel
      WHERE vc.IdCuidador = ?
    `, [id]);

    return res.json(rows);
  } catch (e) {
    return res.status(500).json({ success: false });
  }
});

/**
 * GET CUIDADOR
 */
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT c.*, e.Cidade
       FROM cuidador c
       LEFT JOIN endereco e ON e.IdEndereco = c.IdEndereco
       WHERE c.IdCuidador = ?`,
      [req.params.id]
    );

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (e) {
    return res.status(500).json({ success: false });
  }
});

module.exports = router;