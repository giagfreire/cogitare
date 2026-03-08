const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Cadastrar cuidador
router.post('/', async (req, res) => {
  try {
    const {
      nome,
      email,
      senha,
      telefone,
      cpf,
      dataNascimento,
      idEndereco,
      fumante,
      temFilhos,
      possuiCnh,
      temCarro,
      biografia,
      valorHora,
      fotoUrl
    } = req.body;

    if (!nome || !email || !senha || !telefone || !cpf || !dataNascimento || !idEndereco) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos'
      });
    }

    // Verificar se email já existe
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

    // Verificar se CPF já existe
    const existingCpf = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Cpf = ?',
      [cpf]
    );

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado'
      });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);

    const result = await db.query(
      `INSERT INTO cuidador 
      (Nome, Email, Senha, Telefone, Cpf, DataNascimento, IdEndereco, Fumante, TemFilhos, PossuiCNH, TemCarro, Biografia, ValorHora, FotoUrl)
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

    res.status(201).json({
      success: true,
      message: 'Cuidador cadastrado com sucesso',
      data: {
        idCuidador: result.insertId
      }
    });

  } catch (error) {
    console.error('Erro ao cadastrar cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Buscar cuidador por ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const cuidadores = await db.query(
      `SELECT 
        c.IdCuidador,
        c.Nome,
        c.Email,
        c.Telefone,
        c.Cpf,
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

    const cuidador = cuidadores[0];
    delete cuidador.Senha;

    res.json({
      success: true,
      data: cuidador
    });

  } catch (error) {
    console.error('Erro ao buscar cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Atualizar cuidador
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      nome,
      telefone,
      cpf,
      dataNascimento,
      idEndereco,
      fumante,
      temFilhos,
      possuiCnh,
      temCarro,
      biografia,
      valorHora,
      fotoUrl
    } = req.body;

    const existingCuidador = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE IdCuidador = ?',
      [id]
    );

    if (existingCuidador.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    await db.query(
      `UPDATE cuidador SET
        Nome = ?,
        Telefone = ?,
        Cpf = ?,
        DataNascimento = ?,
        IdEndereco = ?,
        Fumante = ?,
        TemFilhos = ?,
        PossuiCNH = ?,
        TemCarro = ?,
        Biografia = ?,
        ValorHora = ?,
        FotoUrl = ?
      WHERE IdCuidador = ?`,
      [
        nome,
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
        fotoUrl || null,
        id
      ]
    );

    res.json({
      success: true,
      message: 'Cuidador atualizado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao atualizar cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Listar cuidadores
router.get('/', authenticateToken, async (req, res) => {
  try {
    const cuidadores = await db.query(
      `SELECT 
        c.IdCuidador as id,
        c.Nome as nome,
        c.Email as email,
        c.Telefone as telefone,
        c.Cpf as cpf,
        c.DataNascimento as dataNascimento,
        c.FotoUrl as fotoUrl,
        c.Biografia as biografia,
        c.Fumante as fumante,
        c.TemFilhos as temFilhos,
        c.PossuiCNH as possuiCnh,
        c.TemCarro as temCarro,
        c.ValorHora as valorHora,
        e.IdEndereco as idEndereco,
        e.Cidade as cidade,
        e.Bairro as bairro,
        e.Rua as rua,
        e.Numero as numero,
        e.Complemento as complemento,
        e.Cep as cep
      FROM cuidador c
      LEFT JOIN endereco e ON c.IdEndereco = e.IdEndereco`
    );

    res.json({
      success: true,
      data: cuidadores
    });

  } catch (error) {
    console.error('Erro ao listar cuidadores:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Adicionar especialidade ao cuidador
router.post('/especialidade', async (req, res) => {
  try {
    const { idCuidador, especialidade } = req.body;

    const especialidadeResult = await db.query(
      'SELECT IdEspecialidade FROM especialidade WHERE Nome = ?',
      [especialidade]
    );

    if (especialidadeResult.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Especialidade não encontrada'
      });
    }

    const idEspecialidade = especialidadeResult[0].IdEspecialidade;

    await db.query(
      'INSERT INTO cuidadorespecialidade (IdCuidador, IdEspecialidade) VALUES (?, ?)',
      [idCuidador, idEspecialidade]
    );

    res.json({
      success: true,
      message: 'Especialidade adicionada com sucesso'
    });

  } catch (error) {
    console.error('Erro ao adicionar especialidade:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Adicionar serviço ao cuidador
router.post('/servico', async (req, res) => {
  try {
    const { idCuidador, servico } = req.body;

    const servicoResult = await db.query(
      'SELECT IdServico FROM servico WHERE Nome = ?',
      [servico]
    );

    if (servicoResult.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Serviço não encontrado'
      });
    }

    const idServico = servicoResult[0].IdServico;

    await db.query(
      'INSERT INTO cuidadorservico (IdCuidador, IdServico) VALUES (?, ?)',
      [idCuidador, idServico]
    );

    res.json({
      success: true,
      message: 'Serviço adicionado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao adicionar serviço:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Buscar especialidades
router.get('/especialidades/lista', async (req, res) => {
  try {
    const especialidades = await db.query(
      'SELECT IdEspecialidade, Nome FROM especialidade ORDER BY Nome'
    );

    res.json({
      success: true,
      data: especialidades
    });

  } catch (error) {
    console.error('Erro ao buscar especialidades:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Buscar serviços
router.get('/servicos/lista', async (req, res) => {
  try {
    const servicos = await db.query(
      'SELECT IdServico, Nome FROM servico ORDER BY Nome'
    );

    res.json({
      success: true,
      data: servicos
    });

  } catch (error) {
    console.error('Erro ao buscar serviços:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Buscar disponibilidades de um cuidador
router.get('/disponibilidade/:cuidadorId', async (req, res) => {
  try {
    const { cuidadorId } = req.params;

    const disponibilidades = await db.query(
      'SELECT * FROM disponibilidade WHERE IdCuidador = ?',
      [cuidadorId]
    );

    res.json({
      success: true,
      data: disponibilidades
    });

  } catch (error) {
    console.error('Erro ao buscar disponibilidades:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Salvar disponibilidades do cuidador
router.post('/disponibilidade', async (req, res) => {
  try {
    const { idCuidador, disponibilidades } = req.body;

    for (const disp of disponibilidades) {
      const { diaSemana, dataInicio, dataFim, observacoes, recorrente } = disp;

      await db.query(
        `INSERT INTO disponibilidade (IdCuidador, DiaSemana, DataInicio, DataFim, Observacoes, Recorrente)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [idCuidador, diaSemana, dataInicio, dataFim, observacoes || null, recorrente ?? 1]
      );
    }

    res.json({
      success: true,
      message: 'Disponibilidades salvas com sucesso'
    });

  } catch (error) {
    console.error('Erro ao salvar disponibilidades:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

module.exports = router;
