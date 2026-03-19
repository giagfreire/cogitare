const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// CADASTRO DO CUIDADOR
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
      fotoUrl
    } = req.body;

    console.log('BODY RECEBIDO NO CADASTRO:', req.body);

    // validação dos campos obrigatórios do cuidador
    if (!nome || !email || !senha || !telefone || !cpf || !dataNascimento) {
      return res.status(400).json({
        success: false,
        message: 'Preencha nome, email, senha, telefone, cpf e dataNascimento.'
      });
    }

    // validação dos campos obrigatórios do endereço
    if (!cidade || !bairro || !rua || !numero || !cep) {
      return res.status(400).json({
        success: false,
        message: 'Preencha os campos obrigatórios do endereço.'
      });
    }

    // verifica email já cadastrado
    const existingEmail = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Email = ?',
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado'
      });
    }

    // verifica cpf já cadastrado
    const existingCpf = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE CPF = ?',
      [cpf]
    );

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado'
      });
    }

    // criptografa senha
    const hashedPassword = await bcrypt.hash(senha, 10);

    // cria endereço
    const enderecoResult = await db.query(
      `INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    const idEndereco = enderecoResult.insertId;

    // cria cuidador
    const result = await db.query(
      `INSERT INTO cuidador
      (Nome, Email, Senha, Telefone, CPF, DataNascimento, IdEndereco, Fumante, TemFilhos, PossuiCNH, TemCarro, Biografia, ValorHora, FotoUrl)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        nome,
        email,
        hashedPassword,
        telefone,
        cpf,
        dataNascimento,
        idEndereco,
        fumante || 'Não',
        temFilhos || 'Não',
        possuiCnh || 'Não',
        temCarro || 'Não',
        biografia || null,
        valorHora || null,
        fotoUrl || null
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Cuidador cadastrado com sucesso',
      data: {
        idCuidador: result.insertId,
        idEndereco
      }
    });
  } catch (error) {
    console.error('Erro ao cadastrar cuidador:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// BUSCAR CUIDADOR POR ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const cuidadores = await db.query(
      `SELECT 
        c.IdCuidador,
        c.Nome,
        c.Email,
        c.Telefone,
        c.CPF,
        c.DataNascimento,
        c.FotoUrl,
        c.Biografia,
        c.Fumante,
        c.TemFilhos,
        c.PossuiCNH,
        c.TemCarro,
        c.ValorHora,
        e.IdEndereco,
        e.Cidade,
        e.Bairro,
        e.Rua,
        e.Numero,
        e.Complemento,
        e.Cep
      FROM cuidador c
      LEFT JOIN endereco e ON c.IdEndereco = e.IdEndereco
      WHERE c.IdCuidador = ?`,
      [id]
    );

    if (cuidadores.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    return res.json({
      success: true,
      data: cuidadores[0]
    });
  } catch (error) {
    console.error('Erro ao buscar cuidador:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

module.exports = router;

// ATUALIZAR CUIDADOR
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      nome,
      telefone,
      cpf,
      dataNascimento,
      cidade,
      biografia,
      valorHora
    } = req.body;

    // verifica se o cuidador existe
    const cuidadorExistente = await db.query(
      'SELECT * FROM cuidador WHERE IdCuidador = ?',
      [id]
    );

    if (cuidadorExistente.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    const cuidador = cuidadorExistente[0];
    const idEndereco = cuidador.IdEndereco;

    // atualiza cuidador
    await db.query(
      `UPDATE cuidador
       SET Nome = ?, Telefone = ?, CPF = ?, DataNascimento = ?, Biografia = ?, ValorHora = ?
       WHERE IdCuidador = ?`,
      [
        nome || cuidador.Nome,
        telefone || cuidador.Telefone,
        cpf || cuidador.CPF,
        dataNascimento || cuidador.DataNascimento,
        biografia || cuidador.Biografia,
        valorHora || cuidador.ValorHora,
        id
      ]
    );

    // atualiza cidade no endereço, se existir endereço vinculado
    if (idEndereco) {
      await db.query(
        `UPDATE endereco
         SET Cidade = ?
         WHERE IdEndereco = ?`,
        [cidade || null, idEndereco]
      );
    }

    return res.json({
      success: true,
      message: 'Perfil atualizado com sucesso'
    });
  } catch (error) {
    console.error('Erro ao atualizar cuidador:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});