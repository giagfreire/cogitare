const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');

const router = express.Router();

/**
 * CADASTRO CUIDADOR
 */
router.post('/cadastro', async (req, res) => {
  try {
    const { nome, email, senha, telefone, cpf } = req.body;

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

    return res.status(201).json({
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
      error: error.message,
    });
  }
});

/**
 * VAGAS ABERTAS
 */
router.get('/vagas-abertas', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM vaga WHERE Status = 'Aberta'`
    );

    return res.status(200).json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('ERRO VAGAS:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar vagas',
      error: error.message,
    });
  }
});

/**
 * PLANO DO CUIDADOR
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

    if (!rows || rows.length === 0 || !rows[0]) {
      return res.status(200).json({
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

    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: plano,
        UsosPlano: usos,
        LimitePlano: limite,
      },
    });
  } catch (error) {
    console.error('ERRO PLANO:', error);
    return res.status(200).json({
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
 * BUSCAR CUIDADOR
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.query(
      `SELECT
        IdCuidador AS id,
        Nome AS nome,
        Email AS email,
        Telefone AS telefone,
        Cpf AS cpf,
        DataNascimento AS dataNascimento,
        FotoUrl AS fotoUrl,
        Biografia AS biografia,
        Fumante AS fumante,
        TemFilhos AS temFilhos,
        PossuiCNH AS possuiCNH,
        TemCarro AS temCarro,
        ValorHora AS valorHora,
        IdEndereco AS idEndereco,
        COALESCE(UsosPlano, 0) AS usosPlano
      FROM cuidador
      WHERE IdCuidador = ?
      LIMIT 1`,
      [id]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado',
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('ERRO GET CUIDADOR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar cuidador',
      error: error.message,
    });
  }
});

module.exports = router;