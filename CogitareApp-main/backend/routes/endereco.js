const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Criar endereço
router.post('/', async (req, res) => {
  try {
    console.log('Dados recebidos:', req.body);
    
    const {
      rua,
      numero,
      complemento,
      bairro,
      cidade,
      cep
    } = req.body;

    // Tratar valores undefined como null
    const ruaValue = rua || null;
    const numeroValue = numero || null;
    const complementoValue = complemento || null;
    const bairroValue = bairro || null;
    const cidadeValue = cidade || null;
    const cepValue = cep || null;
    
    console.log('Valores tratados:', {
      ruaValue, numeroValue, complementoValue, bairroValue, cidadeValue, cepValue
    });

    const result = await db.query(
      `INSERT INTO endereco (Rua, Numero, Complemento, Bairro, Cidade, Cep) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [ruaValue, numeroValue, complementoValue, bairroValue, cidadeValue, cepValue]
    );

    res.status(201).json({
      success: true,
      message: 'Endereço cadastrado com sucesso',
      data: {
        id: result.insertId
      }
    });

  } catch (error) {
    console.error('Erro ao criar endereço:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Buscar endereço por ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const enderecos = await db.query(
      'SELECT * FROM endereco WHERE IdEndereco = ?',
      [id]
    );

    if (enderecos.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Endereço não encontrado'
      });
    }

    res.json({
      success: true,
      data: enderecos[0]
    });

  } catch (error) {
    console.error('Erro ao buscar endereço:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Atualizar endereço
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      rua,
      numero,
      complemento,
      bairro,
      cidade,
      cep
    } = req.body;

    // Tratar valores undefined como null
    const ruaValue = rua || null;
    const numeroValue = numero || null;
    const complementoValue = complemento || null;
    const bairroValue = bairro || null;
    const cidadeValue = cidade || null;
    const cepValue = cep || null;

    // Verificar se endereço existe
    const existingEndereco = await db.query(
      'SELECT IdEndereco FROM endereco WHERE IdEndereco = ?',
      [id]
    );

    if (existingEndereco.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Endereço não encontrado'
      });
    }

    // Atualizar endereço
    await db.query(
      `UPDATE endereco SET 
       Rua = ?, Numero = ?, Complemento = ?, Bairro = ?, 
       Cidade = ?, Cep = ?
       WHERE IdEndereco = ?`,
      [ruaValue, numeroValue, complementoValue, bairroValue, cidadeValue, cepValue, id]
    );

    res.json({
      success: true,
      message: 'Endereço atualizado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao atualizar endereço:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
