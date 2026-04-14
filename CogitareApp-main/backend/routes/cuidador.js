const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

/**
 * =========================
 * CADASTRO CUIDADOR
 * =========================
 */
router.post('/cadastro', async (req, res) => {
  try {
    const {
      nome,
      email,
      senha,
      telefone,
      cpf,
    } = req.body;

    if (!nome || !email || !senha || !telefone || !cpf) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando',
      });
    }

    const senhaHash = await bcrypt.hash(senha, 10);

    const [result] = await db.query(
      `INSERT INTO cuidador (Nome, Email, Senha, Telefone, Cpf, UsosPlano)
       VALUES (?, ?, ?, ?, ?, 0)`,
      [nome, email, senhaHash, telefone, cpf]
    );

    return res.json({
      success: true,
      data: {
        idCuidador: result.insertId,
      },
    });
  } catch (error) {
    console.error('ERRO CADASTRO:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao cadastrar',
    });
  }
});

/**
 * =========================
 * BUSCAR CUIDADOR
 * =========================
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.query(
      `SELECT * FROM cuidador WHERE IdCuidador = ? LIMIT 1`,
      [id]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('ERRO GET CUIDADOR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar cuidador',
    });
  }
});

/**
 * =========================
 * 🔥 ROTA DO PLANO (FIX PRINCIPAL)
 * =========================
 */
router.get('/:id/plano', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.query(
      `SELECT
        c.IdCuidador,
        COALESCE(c.UsosPlano, 0) AS UsosPlano,
        p.Nome AS PlanoAtual,
        p.LimiteContatos
      FROM cuidador c
      LEFT JOIN assinaturacuidador a
        ON a.IdCuidador = c.IdCuidador AND a.Status = 'Ativa'
      LEFT JOIN plano p
        ON p.IdPlano = a.IdPlano
      WHERE c.IdCuidador = ?
      LIMIT 1`,
      [id]
    );

    console.log('🔥 ROTA /plano EXECUTADA:', rows);

    // 🔥 PROTEÇÃO TOTAL (NUNCA MAIS QUEBRA)
    if (!rows || rows.length === 0 || !rows[0]) {
      return res.json({
        success: true,
        data: {
          PlanoAtual: 'Basico',
          UsosPlano: 0,
          LimitePlano: 5,
        },
      });
    }

    const row = rows[0];

    const plano = row.PlanoAtual || 'Basico';
    const usos = Number(row.UsosPlano) || 0;
    const limite =
      Number(row.LimiteContatos) ||
      (plano.toLowerCase() === 'premium' ? 20 : 5);

    return res.json({
      success: true,
      data: {
        PlanoAtual: plano,
        UsosPlano: usos,
        LimitePlano: limite,
      },
    });
  } catch (error) {
    console.error('❌ ERRO PLANO:', error);

    // 🔥 FALLBACK (mesmo com erro retorna algo)
    return res.json({
      success: true,
      data: {
        PlanoAtual: 'Basico',
        UsosPlano: 0,
        LimitePlano: 5,
      },
    });
  }
});

/**
 * =========================
 * VAGAS ABERTAS
 * =========================
 */
router.get('/vagas-abertas', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM vaga WHERE Status = 'Aberta'`
    );

    return res.json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('ERRO VAGAS:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar vagas',
    });
  }
});

module.exports = router;