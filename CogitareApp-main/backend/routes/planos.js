const express = require('express');
const db = require('../config/database');

const router = express.Router();

// LISTAR PLANOS
router.get('/', async (req, res) => {
  try {
    const planos = await db.query(`
      SELECT * FROM plano WHERE Ativo = 1 ORDER BY Preco ASC
    `);

    res.json({
      success: true,
      data: planos
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false });
  }
});

// VER PLANO DO CUIDADOR
router.get('/cuidador/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(`
      SELECT ac.*, p.*
      FROM assinaturacuidador ac
      JOIN plano p ON ac.IdPlano = p.IdPlano
      WHERE ac.IdCuidador = ? AND ac.Status = 'Ativa'
      LIMIT 1
    `, [id]);

    res.json({
      success: true,
      data: result[0] || null
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false });
  }
});

// ASSINAR PLANO
router.post('/assinar', async (req, res) => {
  try {
    const { idCuidador, idPlano } = req.body;

    await db.query(`
      UPDATE assinaturacuidador
      SET Status = 'Cancelada'
      WHERE IdCuidador = ? AND Status = 'Ativa'
    `, [idCuidador]);

    const result = await db.query(`
      INSERT INTO assinaturacuidador
      (IdCuidador, IdPlano, Status, DataInicio, ContatosUsados)
      VALUES (?, ?, 'Ativa', NOW(), 0)
    `, [idCuidador, idPlano]);

    res.json({
      success: true,
      idAssinatura: result.insertId
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false });
  }
});

module.exports = router;