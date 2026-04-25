const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// =========================
// ENDEREÇO
// =========================
router.post('/endereco', async (req, res) => {
  try {
    const { cidade, bairro, rua, numero, complemento, cep } = req.body;

    if (!cidade || !bairro || !rua || !numero || !cep) {
      return res.status(400).json({
        success: false,
        message: 'Cidade, bairro, rua, número e CEP são obrigatórios',
      });
    }

    const result = await db.query(
      `INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    return res.status(201).json({
      success: true,
      message: 'Endereço cadastrado com sucesso',
      data: { idEndereco: result.insertId },
    });
  } catch (error) {
    console.error('Erro ao cadastrar endereço:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

// =========================
// CADASTRAR RESPONSÁVEL
// =========================
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
      fotoUrl,
    } = req.body;

    if (
      !idEndereco ||
      !cpf ||
      !nome ||
      !email ||
      !telefone ||
      !dataNascimento ||
      !senha
    ) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos',
      });
    }

    const existingCpf = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Cpf = ?',
      [cpf]
    );

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado',
      });
    }

    const existingEmail = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Email = ?',
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado',
      });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);

    const result = await db.query(
      `INSERT INTO responsavel
      (IdEndereco, Cpf, Nome, Email, Telefone, DataNascimento, Senha, FotoUrl)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        idEndereco,
        cpf,
        nome,
        email,
        telefone,
        dataNascimento,
        hashedPassword,
        fotoUrl || null,
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Responsável cadastrado com sucesso',
      data: { idResponsavel: result.insertId },
    });
  } catch (error) {
    console.error('Erro ao cadastrar responsável:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

// =========================
// CADASTRO COMPLETO
// =========================
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
      fotoUrl,
    } = req.body;

    if (
      !cidade ||
      !bairro ||
      !rua ||
      !numero ||
      !cep ||
      !cpf ||
      !nome ||
      !email ||
      !telefone ||
      !dataNascimento ||
      !senha
    ) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos',
      });
    }

    const existingCpf = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Cpf = ?',
      [cpf]
    );

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado',
      });
    }

    const existingEmail = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Email = ?',
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado',
      });
    }

    connection = await db.getConnection();
    await connection.beginTransaction();

    const [addressResult] = await connection.execute(
      `INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    const idEndereco = addressResult.insertId;
    const hashedPassword = await bcrypt.hash(senha, 10);

    const [guardianResult] = await connection.execute(
      `INSERT INTO responsavel
      (IdEndereco, Cpf, Nome, Email, Telefone, DataNascimento, Senha, FotoUrl)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        idEndereco,
        cpf,
        nome,
        email,
        telefone,
        dataNascimento,
        hashedPassword,
        fotoUrl || null,
      ]
    );

    await connection.commit();

    return res.status(201).json({
      success: true,
      message: 'Responsável cadastrado com sucesso',
      data: {
        idResponsavel: guardianResult.insertId,
        idEndereco,
      },
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }

    console.error('Erro no cadastro completo:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// =========================
// LISTAR RESPONSÁVEIS
// =========================
router.get('/', authenticateToken, async (req, res) => {
  try {
    const responsaveis = await db.query(`
      SELECT
        r.*,
        e.Cidade,
        e.Bairro,
        e.Rua,
        e.Numero,
        e.Complemento,
        e.Cep
      FROM responsavel r
      LEFT JOIN endereco e ON r.IdEndereco = e.IdEndereco
    `);

    return res.json({
      success: true,
      message: 'Responsáveis listados com sucesso',
      data: responsaveis,
    });
  } catch (error) {
    console.error('Erro ao listar responsáveis:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

// =========================
// PERFIL DO RESPONSÁVEL
// =========================

// Buscar perfil do responsável logado
router.get('/perfil', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem acessar o perfil',
      });
    }

    const rows = await db.query(
      `SELECT
        IdResponsavel,
        IdEndereco,
        Nome,
        Email,
        Telefone,
        Cpf,
        DataNascimento,
        FotoUrl
      FROM responsavel
      WHERE IdResponsavel = ?`,
      [req.user.id]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('ERRO AO BUSCAR PERFIL:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar perfil',
      error: error.message,
    });
  }
});

// Atualizar perfil do responsável logado
router.put('/perfil', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem editar o perfil',
      });
    }

    const { nome, email, telefone, dataNascimento, fotoUrl } = req.body;

    if (!nome || !email || !telefone || !dataNascimento) {
      return res.status(400).json({
        success: false,
        message: 'Nome, email, telefone e data de nascimento são obrigatórios',
      });
    }

    const emailExistente = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE Email = ? AND IdResponsavel <> ?',
      [email, req.user.id]
    );

    if (emailExistente.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Este email já está em uso por outro responsável',
      });
    }

    await db.query(
      `UPDATE responsavel
       SET Nome = ?, Email = ?, Telefone = ?, DataNascimento = ?, FotoUrl = ?
       WHERE IdResponsavel = ?`,
      [nome, email, telefone, dataNascimento, fotoUrl || null, req.user.id]
    );

    const atualizado = await db.query(
      `SELECT
        IdResponsavel,
        IdEndereco,
        Nome,
        Email,
        Telefone,
        Cpf,
        DataNascimento,
        FotoUrl
      FROM responsavel
      WHERE IdResponsavel = ?`,
      [req.user.id]
    );

    return res.json({
      success: true,
      message: 'Perfil atualizado com sucesso',
      data: atualizado[0],
    });
  } catch (error) {
    console.error('ERRO AO ATUALIZAR PERFIL:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar perfil',
      error: error.message,
    });
  }
});

// Apagar conta do responsável logado
router.delete('/perfil', authenticateToken, async (req, res) => {
  let connection;

  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem apagar a conta',
      });
    }

    connection = await db.getConnection();
    await connection.beginTransaction();

    // apaga vínculos em vagacuidador das vagas desse responsável
    await connection.execute(
      `DELETE vc
       FROM vagacuidador vc
       INNER JOIN vaga v ON vc.IdVaga = v.IdVaga
       WHERE v.IdResponsavel = ?`,
      [req.user.id]
    );

    // apaga vagas do responsável
    await connection.execute(
      'DELETE FROM vaga WHERE IdResponsavel = ?',
      [req.user.id]
    );

    // apaga a conta
    await connection.execute(
      'DELETE FROM responsavel WHERE IdResponsavel = ?',
      [req.user.id]
    );

    await connection.commit();

    return res.json({
      success: true,
      message: 'Conta apagada com sucesso',
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }

    console.error('ERRO AO APAGAR CONTA:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao apagar conta',
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// =========================
// VAGAS
// =========================
router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem criar vagas',
      });
    }

    const {
      titulo,
      descricao,
      cidade,
      dataServico,
      horaInicio,
      horaFim,
      valor,
    } = req.body;

    if (
      !titulo ||
      !descricao ||
      !cidade ||
      !dataServico ||
      !horaInicio ||
      !horaFim ||
      valor === undefined ||
      valor === null
    ) {
      return res.status(400).json({
        success: false,
        message: 'Todos os campos obrigatórios devem ser preenchidos',
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

    return res.json({
      success: true,
      message: 'Vagas listadas com sucesso',
      data: vagas,
    });
  } catch (error) {
    console.error('Erro ao listar vagas:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

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

    return res.json({
      success: true,
      message: 'Vagas abertas listadas com sucesso',
      data: vagas,
    });
  } catch (error) {
    console.error('Erro ao listar vagas abertas:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

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
      valor,
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
        message: 'Preencha todos os campos obrigatórios da vaga',
      });
    }

    const responsavelRows = await db.query(
      'SELECT IdResponsavel FROM responsavel WHERE IdResponsavel = ?',
      [idResponsavel]
    );

    if (!responsavelRows || responsavelRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado',
      });
    }

    const result = await db.query(
      `INSERT INTO vaga
      (IdResponsavel, Titulo, Descricao, Cidade, DataServico, HoraInicio, HoraFim, Valor, Status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Aberta')`,
      [idResponsavel, titulo, descricao, cidade, dataServico, horaInicio, horaFim, valor]
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
      message: 'Erro ao criar vaga',
      error: error.message,
    });
  }
});

router.get('/:id/vagas', async (req, res) => {
  try {
    const { id } = req.params;

    const rows = await db.query(
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

    return res.json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('Erro ao listar vagas do responsável:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao listar vagas do responsável',
      error: error.message,
    });
  }
});

router.put('/vagas/:idVaga', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem editar vagas',
      });
    }

    const { idVaga } = req.params;
    const {
      titulo,
      descricao,
      cidade,
      dataServico,
      horaInicio,
      horaFim,
      valor,
    } = req.body;

    const vagas = await db.query(
      'SELECT * FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?',
      [idVaga, req.user.id]
    );

    if (vagas.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada',
      });
    }

    await db.query(
      `UPDATE vaga
       SET Titulo = ?, Descricao = ?, Cidade = ?, DataServico = ?, HoraInicio = ?, HoraFim = ?, Valor = ?
       WHERE IdVaga = ? AND IdResponsavel = ?`,
      [titulo, descricao, cidade, dataServico, horaInicio, horaFim, valor, idVaga, req.user.id]
    );

    return res.json({
      success: true,
      message: 'Vaga atualizada com sucesso',
    });
  } catch (error) {
    console.error('Erro ao editar vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

router.put('/vagas/:idVaga/status', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem alterar status de vagas',
      });
    }

    const { idVaga } = req.params;
    const { status } = req.body;

    if (!status || !['Aberta', 'Encerrada'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status inválido',
      });
    }

    const vagas = await db.query(
      'SELECT * FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?',
      [idVaga, req.user.id]
    );

    if (vagas.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada',
      });
    }

    await db.query(
      'UPDATE vaga SET Status = ? WHERE IdVaga = ? AND IdResponsavel = ?',
      [status, idVaga, req.user.id]
    );

    return res.json({
      success: true,
      message: 'Status da vaga atualizado com sucesso',
    });
  } catch (error) {
    console.error('Erro ao atualizar status da vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

router.delete('/vagas/:idVaga', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem excluir vagas',
      });
    }

    const { idVaga } = req.params;

    const vagas = await db.query(
      'SELECT * FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?',
      [idVaga, req.user.id]
    );

    if (vagas.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada',
      });
    }

    await db.query(
  'DELETE FROM vagacuidador WHERE IdVaga = ?',
  [idVaga]
);

await db.query(
  'DELETE FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?',
  [idVaga, req.user.id]
);

    return res.json({
      success: true,
      message: 'Vaga excluída com sucesso',
    });
  } catch (error) {
    console.error('Erro ao excluir vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

router.get('/vagas/:idVaga/interessados', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'responsavel') {
      return res.status(403).json({
        success: false,
        message: 'Apenas responsáveis podem ver interessados',
      });
    }

    const { idVaga } = req.params;

    const vagas = await db.query(
      'SELECT * FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?',
      [idVaga, req.user.id]
    );

    if (vagas.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada',
      });
    }

    const interessados = await db.query(
      `SELECT
        vc.IdVagaCuidador,
        vc.IdVaga,
        vc.IdCuidador,
        vc.DataAceite,
        c.Nome,
        c.Email,
        c.Telefone,
        c.Biografia,
        c.ValorHora
      FROM vagacuidador vc
      INNER JOIN cuidador c ON c.IdCuidador = vc.IdCuidador
      WHERE vc.IdVaga = ?
      ORDER BY vc.IdVagaCuidador DESC`,
      [idVaga]
    );

    return res.json({
      success: true,
      message: 'Interessados listados com sucesso',
      data: interessados,
    });
  } catch (error) {
    console.error('Erro ao listar interessados:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

module.exports = router;