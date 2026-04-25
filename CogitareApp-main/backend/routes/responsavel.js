const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem criar vagas',
      });
    }

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

    if (!idIdoso || !titulo || !cep || !cidade || !dataServico || !horaInicio || !horaFim) {
      return res.status(400).json({
        success: false,
        message: 'Preencha idoso, título, localidade, data e horários.',
      });
    }

    const result = await db.query(
      `INSERT INTO vaga
      (IdResponsavel, IdIdoso, Titulo, Descricao, Cep, Cidade, Bairro, Rua, DataServico, HoraInicio, HoraFim, Valor, Status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        idIdoso,
        titulo,
        'Valor a combinar com o cuidador.',
        cep,
        cidade,
        bairro || null,
        rua || null,
        dataServico,
        horaInicio,
        horaFim,
        0,
        'Aberta',
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Vaga criada com sucesso',
      data: { idVaga: result.insertId },
    });
  } catch (error) {
    console.error('Erro ao criar vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

module.exports = router;