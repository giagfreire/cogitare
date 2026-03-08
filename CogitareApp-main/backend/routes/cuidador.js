const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Criar cuidador
router.post('/', async (req, res) => {
  try {
    const {
      nome,
      email,
      senha,
      telefone,
      cpf,
      data_nascimento,
      endereco_id,
      fumante,
      tem_filhos,
      possui_cnh,
      tem_carro,
      biografia,
      valor_hora
    } = req.body;

    // Verificar se email já existe
    const existingUser = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Email = ?',
      [email]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado'
      });
    }

    // Criptografar senha
    const hashedPassword = await bcrypt.hash(senha, 10);

    // Inserir cuidador
    const result = await db.query(
      `INSERT INTO cuidador (Nome, Email, Senha, Telefone, Cpf, DataNascimento, IdEndereco, Fumante, TemFilhos, PossuiCNH, TemCarro, Biografia, ValorHora) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [nome, email, hashedPassword, telefone, cpf, data_nascimento, endereco_id, fumante || 'Não', tem_filhos || 'Não', possui_cnh || 'Não', tem_carro || 'Não', biografia || null, valor_hora || null]
    );

    res.status(201).json({
      success: true,
      message: 'Cuidador cadastrado com sucesso',
      data: {
        id: result.insertId
      }
    });

  } catch (error) {
    console.error('Erro ao criar cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Buscar cuidador por ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const cuidadores = await db.query(
      `SELECT c.*, e.* FROM cuidador c 
       LEFT JOIN endereco e ON c.endereco_id = e.id 
       WHERE c.id = ?`,
      [id]
    );

    if (cuidadores.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    const cuidador = cuidadores[0];
    delete cuidador.senha; // Remover senha da resposta

    res.json({
      success: true,
      data: cuidador
    });

  } catch (error) {
    console.error('Erro ao buscar cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
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
      data_nascimento,
      endereco_id
    } = req.body;

    // Verificar se cuidador existe
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

    // Atualizar cuidador
    await db.query(
      `UPDATE cuidador SET 
       nome = ?, telefone = ?, cpf = ?, data_nascimento = ?, endereco_id = ?
       WHERE id = ?`,
      [nome, telefone, cpf, data_nascimento, endereco_id, id]
    );

    res.json({
      success: true,
      message: 'Cuidador atualizado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao atualizar cuidador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Listar cuidadores
router.get('/', authenticateToken, async (req, res) => {
  try {
    const cuidadores = await db.query(
      `SELECT c.IdCuidador as id, c.Nome as nome, c.Email as email, c.Telefone as telefone, c.Cpf as cpf, c.DataNascimento as data_nascimento,
              c.FotoUrl as foto_url, c.Biografia as biografia, c.Fumante as fumante, c.TemFilhos as tem_filhos, 
              c.PossuiCNH as possui_cnh, c.TemCarro as tem_carro,
              e.IdEndereco as endereco_id, e.Cidade as cidade, e.Bairro as bairro, e.Rua as logradouro, 
              e.Numero as numero, e.Complemento as complemento, e.Cep as cep
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
      message: 'Erro interno do servidor'
    });
  }
});

// Criar especialidade do cuidador
router.post('/especialidade', async (req, res) => {
  try {
    const { cuidador_id, especialidade } = req.body;

    // Buscar ID da especialidade pelo nome
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

    const especialidadeId = especialidadeResult[0].IdEspecialidade;

    // Inserir relação cuidador-especialidade
    await db.query(
      'INSERT INTO cuidadorespecialidade (IdCuidador, IdEspecialidade) VALUES (?, ?)',
      [cuidador_id, especialidadeId]
    );

    res.json({
      success: true,
      message: 'Especialidade adicionada com sucesso'
    });

  } catch (error) {
    console.error('Erro ao adicionar especialidade:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Criar serviço do cuidador
router.post('/servico', async (req, res) => {
  try {
    const { cuidador_id, servico } = req.body;

    // Buscar ID do serviço pelo nome
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

    const servicoId = servicoResult[0].IdServico;

    // Inserir relação cuidador-serviço
    await db.query(
      'INSERT INTO cuidadorservico (IdCuidador, IdServico) VALUES (?, ?)',
      [cuidador_id, servicoId]
    );

    res.json({
      success: true,
      message: 'Serviço adicionado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao adicionar serviço:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET - Buscar todas as especialidades
router.get('/especialidades', async (req, res) => {
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
      message: 'Erro interno do servidor'
    });
  }
});

// GET - Buscar todos os serviços
router.get('/servicos', async (req, res) => {
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
      message: 'Erro interno do servidor'
    });
  }
});

// GET - Verificar disponibilidades de um cuidador
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
      message: 'Erro interno do servidor'
    });
  }
});

// POST - Salvar disponibilidades do cuidador
router.post('/disponibilidade', async (req, res) => {
  try {
    const { cuidador_id, disponibilidades } = req.body;

    // Inserir cada disponibilidade
    for (const disp of disponibilidades) {
      const { dia_semana, data_inicio, data_fim, observacoes, recorrente } = disp;
      
      // Garantir formato HH:MM:SS
      const horarioInicio = data_inicio.includes(':') ? data_inicio : `${data_inicio}:00`;
      const horarioFim = data_fim.includes(':') ? data_fim : `${data_fim}:00`;
      
      await db.query(
        `INSERT INTO disponibilidade (IdCuidador, DiaSemana, DataInicio, DataFim, Observacoes, Recorrente) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [cuidador_id, dia_semana, horarioInicio, horarioFim, observacoes || null, recorrente || 1]
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
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
