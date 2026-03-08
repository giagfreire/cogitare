const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Cadastrar endereço
router.post('/endereco', async (req, res) => {
  try {
    const { cidade, bairro, rua, numero, complemento, cep } = req.body;

    if (!cidade || !bairro || !rua || !numero || !cep) {
      return res.status(400).json({
        success: false,
        message: 'Cidade, bairro, rua, número e CEP são obrigatórios'
      });
    }

    const result = await db.query(
      'INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep) VALUES (?, ?, ?, ?, ?, ?)',
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    res.status(201).json({
      success: true,
      message: 'Endereço cadastrado com sucesso',
      data: {
        idEndereco: result.insertId
      }
    });
  } catch (error) {
    console.error('Erro ao cadastrar endereço:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Cadastrar responsável
router.post('/', async (req, res) => {
  try {
    const {
      idEndereco,
      cpf,
      nome,
      email,
      telefone,
      dataNascimento,
      senha,
      fotoUrl
    } = req.body;

    if (!idEndereco || !cpf || !nome || !email || !telefone || !dataNascimento || !senha) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos'
      });
    }

    const existingCpf = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Cpf = ?',
      [cpf]
    );

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado'
      });
    }

    const existingEmail = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Email = ?',
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado'
      });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);

    const result = await db.query(
      'INSERT INTO responsavel (IdEndereco, Cpf, Nome, Email, Telefone, DataNascimento, Senha, FotoUrl) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [idEndereco, cpf, nome, email, telefone, dataNascimento, hashedPassword, fotoUrl || null]
    );

    res.status(201).json({
      success: true,
      message: 'Responsável cadastrado com sucesso',
      data: {
        idResponsavel: result.insertId
      }
    });
  } catch (error) {
    console.error('Erro ao cadastrar responsável:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Cadastro completo (endereço + responsável)
router.post('/completo', async (req, res) => {
  let connection;

  try {
    const {
      cidade,
      bairro,
      rua,
      numero,
      complemento,
      cep,
      cpf,
      nome,
      email,
      telefone,
      dataNascimento,
      senha,
      fotoUrl
    } = req.body;

    if (!cidade || !bairro || !rua || !numero || !cep || !cpf || !nome || !email || !telefone || !dataNascimento || !senha) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos'
      });
    }

    const existingCpf = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Cpf = ?',
      [cpf]
    );

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado'
      });
    }

    const existingEmail = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Email = ?',
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado'
      });
    }

    connection = await db.getConnection();
    await connection.beginTransaction();

    const [addressResult] = await connection.execute(
      'INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep) VALUES (?, ?, ?, ?, ?, ?)',
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    const idEndereco = addressResult.insertId;
    const hashedPassword = await bcrypt.hash(senha, 10);

    const [guardianResult] = await connection.execute(
      'INSERT INTO responsavel (IdEndereco, Cpf, Nome, Email, Telefone, DataNascimento, Senha, FotoUrl) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [idEndereco, cpf, nome, email, telefone, dataNascimento, hashedPassword, fotoUrl || null]
    );

    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'Responsável cadastrado com sucesso',
      data: {
        idResponsavel: guardianResult.insertId,
        idEndereco: idEndereco
      }
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }

    console.error('Erro no cadastro completo:', error);

    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Listar responsáveis
router.get('/', authenticateToken, async (req, res) => {
  try {
    const responsaveis = await db.query(`
      SELECT r.*, e.Cidade, e.Bairro, e.Rua, e.Numero, e.Complemento, e.Cep
      FROM responsavel r
      LEFT JOIN endereco e ON r.IdEndereco = e.IdEndereco
    `);

    res.json({
      success: true,
      message: 'Responsáveis listados com sucesso',
      data: responsaveis
    });
  } catch (error) {
    console.error('Erro ao listar responsáveis:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Buscar responsável por ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const responsaveis = await db.query(`
      SELECT r.*, e.Cidade, e.Bairro, e.Rua, e.Numero, e.Complemento, e.Cep
      FROM responsavel r
      LEFT JOIN endereco e ON r.IdEndereco = e.IdEndereco
      WHERE r.IdResponsavel = ?
    `, [id]);

    if (responsaveis.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado'
      });
    }

    res.json({
      success: true,
      message: 'Responsável encontrado',
      data: responsaveis[0]
    });
  } catch (error) {
    console.error('Erro ao buscar responsável:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

module.exports = router;
