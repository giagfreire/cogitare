const express = require('express');
const db = require('../config/database');

const router = express.Router();

// Criar idoso
router.post('/', async (req, res) => {
  try {
    const {
      IdResponsavel,
      IdMobilidade,
      IdNivelAutonomia,
      Nome,
      DataNascimento,
      Sexo,
      CuidadosMedicos,
      DescricaoExtra,
      FotoUrl,
      SelectedServices,
      Availability
    } = req.body;

    // Validar campos obrigatórios
    if (!Nome || !DataNascimento || !Sexo || !IdResponsavel || !IdMobilidade || !IdNivelAutonomia) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos'
      });
    }

    // Verificar se responsável existe
    const existingGuardian = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE IdResponsavel = ?',
      [IdResponsavel]
    );

    if (existingGuardian.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Responsável não encontrado'
      });
    }

    // Inserir idoso
    const result = await db.query(
      `INSERT INTO idoso (IdResponsavel, IdMobilidade, IdNivelAutonomia, Nome, DataNascimento, Sexo, CuidadosMedicos, DescricaoExtra, FotoUrl) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        IdResponsavel, 
        IdMobilidade, 
        IdNivelAutonomia, 
        Nome, 
        DataNascimento, 
        Sexo, 
        CuidadosMedicos || null, 
        DescricaoExtra || null, 
        FotoUrl || null
      ]
    );

    const idosoId = result.insertId;

    // Salvar serviços selecionados (se houver)
    if (SelectedServices && SelectedServices.length > 0) {
      // Por enquanto, vamos apenas logar os serviços selecionados
      // Futuramente pode ser implementada uma tabela de relacionamento
      console.log('Serviços selecionados para idoso', idosoId, ':', SelectedServices);
    }

    // Salvar disponibilidade (se houver)
    if (Availability && Availability.length > 0) {
      // Por enquanto, vamos apenas logar a disponibilidade
      // Futuramente pode ser implementada uma tabela de disponibilidade para idosos
      console.log('Disponibilidade para idoso', idosoId, ':', Availability);
    }

    res.status(201).json({
      success: true,
      message: 'Idoso cadastrado com sucesso',
      data: {
        IdIdoso: idosoId
      }
    });

  } catch (error) {
    console.error('Erro ao criar idoso:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Listar idosos
router.get('/', async (req, res) => {
  try {
    const idosos = await db.query(
      `SELECT i.*, r.Nome as ResponsavelNome, m.Descricao as MobilidadeDesc, na.Descricao as AutonomiaDesc
       FROM idoso i 
       LEFT JOIN responsavel r ON i.IdResponsavel = r.IdResponsavel 
       LEFT JOIN mobilidade m ON i.IdMobilidade = m.IdMobilidade
       LEFT JOIN nivelautonomia na ON i.IdNivelAutonomia = na.IdNivelAutonomia`
    );

    res.json({
      success: true,
      data: idosos
    });

  } catch (error) {
    console.error('Erro ao listar idosos:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Buscar idoso por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const idosos = await db.query(
      `SELECT i.*, r.Nome as ResponsavelNome, m.Descricao as MobilidadeDesc, na.Descricao as AutonomiaDesc
       FROM idoso i 
       LEFT JOIN responsavel r ON i.IdResponsavel = r.IdResponsavel 
       LEFT JOIN mobilidade m ON i.IdMobilidade = m.IdMobilidade
       LEFT JOIN nivelautonomia na ON i.IdNivelAutonomia = na.IdNivelAutonomia
       WHERE i.IdIdoso = ?`,
      [id]
    );

    if (idosos.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Idoso não encontrado'
      });
    }

    res.json({
      success: true,
      data: idosos[0]
    });

  } catch (error) {
    console.error('Erro ao buscar idoso:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;