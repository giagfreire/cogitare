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

// =========================
// =========================
// ROTAS DE VAGAS
// =========================

// Criar vaga
router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem criar vagas'
      });
    }

    const {
      titulo,
      descricao,
      cidade,
      dataServico,
      horaInicio,
      horaFim,
      valor
    } = req.body;

    if (!titulo || !descricao || !cidade || !dataServico || !horaInicio || !horaFim || !valor) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos'
      });
    }

    const result = await db.query(
      `INSERT INTO vaga 
      (IdResponsavel, Titulo, Descricao, Cidade, DataServico, HoraInicio, HoraFim, Valor, Status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        titulo,
        descricao,
        cidade,
        dataServico,
        horaInicio,
        horaFim,
        valor,
        'Aberta'
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Vaga criada com sucesso',
      data: {
        idVaga: result.insertId
      }
    });
  } catch (error) {
    console.error('Erro ao criar vaga:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Listar vagas do responsável logado
router.get('/vagas/minhas', authenticateToken, async (req, res) => {
  try {
    const vagas = await db.query(
      `SELECT 
        v.*,
        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel
      FROM vaga v
      INNER JOIN responsavel r ON v.IdResponsavel = r.IdResponsavel
      WHERE v.IdResponsavel = ?
      ORDER BY v.IdVaga DESC`,
      [req.user.id]
    );

    res.json({
      success: true,
      message: 'Vagas listadas com sucesso',
      data: vagas
    });
  } catch (error) {
    console.error('Erro ao listar vagas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Listar vagas abertas (para o cuidador)
router.get('/vagas/abertas', authenticateToken, async (req, res) => {
  try {
    const vagas = await db.query(
      `SELECT
        v.*,
        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel
      FROM vaga v
      INNER JOIN responsavel r ON v.IdResponsavel = r.IdResponsavel
      WHERE v.Status = 'Aberta'
      ORDER BY v.IdVaga DESC`
    );

    res.json({
      success: true,
      message: 'Vagas abertas listadas com sucesso',
      data: vagas
    });
  } catch (error) {
    console.error('Erro ao listar vagas abertas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});
// CRIAR VAGA
router.post('/criar-vaga', async (req, res) => {
  try {
    const {
      idResponsavel,
      titulo,
      descricao,
      cidade,
      dataServico,
      horaInicio,
      horaFim,
      valor
    } = req.body;

    if (
      !idResponsavel ||
      !titulo ||
      !descricao ||
      !cidade ||
      !dataServico ||
      !horaInicio ||
      !horaFim ||
      valor == null
    ) {
      return res.status(400).json({
        success: false,
        message: 'Preencha todos os campos obrigatórios da vaga'
      });
    }

    const responsavelResult = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE IdResponsavel = ?',
      [idResponsavel]
    );
    const responsavelRows = Array.isArray(responsavelResult[0])
      ? responsavelResult[0]
      : responsavelResult;

    if (!responsavelRows || responsavelRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado'
      });
    }

    const result = await db.query(
      `INSERT INTO vaga
      (IdResponsavel, Titulo, Descricao, Cidade, DataServico, HoraInicio, HoraFim, Valor, Status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Aberta')`,
      [
        idResponsavel,
        titulo,
        descricao,
        cidade,
        dataServico,
        horaInicio,
        horaFim,
        valor
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Vaga criada com sucesso',
      data: {
        idVaga: result.insertId
      }
    });
  } catch (error) {
    console.error('Erro ao criar vaga:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao criar vaga',
      error: error.message
    });
  }
});
// LISTAR VAGAS DO RESPONSÁVEL
router.get('/:id/vagas', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT 
        IdVaga,
        IdResponsavel,
        Titulo,
        Descricao,
        Cidade,
        DataServico,
        HoraInicio,
        HoraFim,
        Valor,
        Status,
        DataCriacao
      FROM vaga
      WHERE IdResponsavel = ?
      ORDER BY DataCriacao DESC`,
      [id]
    );

    const rows = Array.isArray(result[0]) ? result[0] : result;

    return res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Erro ao listar vagas do responsável:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao listar vagas do responsável',
      error: error.message
    });
  }
});

module.exports = router;