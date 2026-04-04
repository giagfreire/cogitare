const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

function normalizeRows(result) {
  if (Array.isArray(result) && Array.isArray(result[0])) {
    return result[0];
  }
  return result;
}

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

    if (!nome || !email || !senha || !telefone || !cpf || !dataNascimento) {
      return res.status(400).json({
        success: false,
        message: 'Preencha nome, email, senha, telefone, cpf e dataNascimento.'
      });
    }

    if (!cidade || !bairro || !rua || !numero || !cep) {
      return res.status(400).json({
        success: false,
        message: 'Preencha os campos obrigatórios do endereço.'
      });
    }

    const existingEmailResult = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Email = ?',
      [email]
    );
    const existingEmail = normalizeRows(existingEmailResult);

    if (existingEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado'
      });
    }

    const existingCpfResult = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE CPF = ?',
      [cpf]
    );
    const existingCpf = normalizeRows(existingCpfResult);

    if (existingCpf.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'CPF já cadastrado'
      });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);

    const enderecoResult = await db.query(
      `INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    const idEndereco = enderecoResult.insertId;

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
// BUSCAR STATUS DE USO DO PLANO
router.get('/:id/status-plano', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      'SELECT PlanoAtual, UsosPlano FROM cuidador WHERE IdCuidador = ?',
      [id]
    );
    const rows = normalizeRows(result);

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    const cuidador = rows[0];
    const planoAtual = cuidador.PlanoAtual || 'Basico';
    const usosPlano = Number(cuidador.UsosPlano || 0);
    const limitePlano = planoAtual === 'Premium' ? 20 : 5;
    const restante = limitePlano - usosPlano;

    return res.json({
      success: true,
      data: {
        planoAtual,
        usosPlano,
        limitePlano,
        restante: restante < 0 ? 0 : restante
      }
    });
  } catch (error) {
    console.error('Erro ao buscar status do plano:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar status do plano',
      error: error.message
    });
  }
});

// BUSCAR VAGAS ABERTAS
router.get('/vagas-abertas', async (req, res) => {
  try {
    const vagasResult = await db.query(`
      SELECT 
        v.IdVaga,
        v.IdResponsavel,
        v.Titulo,
        v.Descricao,
        v.Cidade,
        v.DataServico,
        v.HoraInicio,
        v.HoraFim,
        v.Valor,
        v.Status,
        v.DataCriacao,
        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel
      FROM vaga v
      INNER JOIN responsavel r 
        ON v.IdResponsavel = r.IdResponsavel
      WHERE v.Status = 'Aberta'
      ORDER BY v.DataServico ASC, v.HoraInicio ASC
    `);

    const vagas = normalizeRows(vagasResult);

    return res.json({
      success: true,
      data: vagas
    });
  } catch (error) {
    console.error('Erro ao buscar vagas abertas:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar vagas abertas',
      error: error.message
    });
  }
});

// ACEITAR VAGA
router.post('/aceitar-vaga', async (req, res) => {
  try {
    const { idVaga, idCuidador } = req.body;

    if (!idVaga || !idCuidador) {
      return res.status(400).json({
        success: false,
        message: 'Id da vaga e Id do cuidador são obrigatórios'
      });
    }

    // Verifica se a vaga existe
    const vagaResult = await db.query(
      'SELECT * FROM vaga WHERE IdVaga = ?',
      [idVaga]
    );
    const vagaRows = normalizeRows(vagaResult);

    if (vagaRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada'
      });
    }

    // Verifica se a vaga está aberta
    if (vagaRows[0].Status !== 'Aberta') {
      return res.status(400).json({
        success: false,
        message: 'Essa vaga não está mais disponível'
      });
    }

    // Verifica cuidador
    const cuidadorResult = await db.query(
      'SELECT PlanoAtual, UsosPlano FROM cuidador WHERE IdCuidador = ?',
      [idCuidador]
    );
    const cuidadorRows = normalizeRows(cuidadorResult);

    if (cuidadorRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    const cuidador = cuidadorRows[0];
    const planoAtual = cuidador.PlanoAtual || 'Basico';
    const usosPlano = Number(cuidador.UsosPlano || 0);

    const limitePlano = planoAtual === 'Premium' ? 20 : 5;

    // Verifica limite do plano
    if (usosPlano >= limitePlano) {
      return res.status(403).json({
        success: false,
        message: `Seu plano ${planoAtual} atingiu o limite de ${limitePlano} vagas aceitas. Faça upgrade para continuar.`
      });
    }

    // Verifica se já aceitou essa vaga
    const aceiteResult = await db.query(
      'SELECT * FROM vagacuidador WHERE IdVaga = ? AND IdCuidador = ?',
      [idVaga, idCuidador]
    );
    const aceiteRows = normalizeRows(aceiteResult);

    if (aceiteRows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Você já aceitou essa vaga'
      });
    }

    // Salva o aceite
    await db.query(
      `INSERT INTO vagacuidador (IdVaga, IdCuidador, Status)
       VALUES (?, ?, 'Aceita')`,
      [idVaga, idCuidador]
    );

    // Incrementa uso do plano
    await db.query(
      'UPDATE cuidador SET UsosPlano = COALESCE(UsosPlano, 0) + 1 WHERE IdCuidador = ?',
      [idCuidador]
    );

    return res.json({
      success: true,
      message: 'Vaga aceita com sucesso'
    });
  } catch (error) {
    console.error('Erro ao aceitar vaga:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao aceitar vaga',
      error: error.message
    });
  }
});

// BUSCAR CUIDADOR POR ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const cuidadoresResult = await db.query(
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

    const cuidadores = normalizeRows(cuidadoresResult);

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

// SALVAR DISPONIBILIDADE
router.post('/:id/disponibilidade', async (req, res) => {
  try {
    const { id } = req.params;
    const { disponibilidade } = req.body;

    if (!Array.isArray(disponibilidade)) {
      return res.status(400).json({
        success: false,
        message: 'Disponibilidade inválida'
      });
    }

    await db.query(
      'DELETE FROM disponibilidade WHERE IdCuidador = ?',
      [id]
    );

    for (const item of disponibilidade) {
      await db.query(
        `INSERT INTO disponibilidade 
        (IdCuidador, DiaSemana, DataInicio, DataFim, Observacoes, Recorrente)
        VALUES (?, ?, ?, ?, ?, ?)`,
        [
          id,
          item.dia,
          item.ativo ? item.inicio : null,
          item.ativo ? item.fim : null,
          null,
          1
        ]
      );
    }

    return res.json({
      success: true,
      message: 'Disponibilidade salva com sucesso'
    });
  } catch (error) {
    console.error('Erro ao salvar disponibilidade:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao salvar disponibilidade',
      error: error.message
    });
  }
});

// BUSCAR DISPONIBILIDADE
router.get('/:id/disponibilidade', async (req, res) => {
  try {
    const { id } = req.params;

    const rowsResult = await db.query(
      'SELECT * FROM disponibilidade WHERE IdCuidador = ?',
      [id]
    );
    const rows = normalizeRows(rowsResult);

    return res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Erro ao buscar disponibilidade:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar disponibilidade',
      error: error.message
    });
  }
});

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

    const cuidadorExistenteResult = await db.query(
      'SELECT * FROM cuidador WHERE IdCuidador = ?',
      [id]
    );
    const cuidadorExistente = normalizeRows(cuidadorExistenteResult);

    if (cuidadorExistente.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    const cuidador = cuidadorExistente[0];
    const idEndereco = cuidador.IdEndereco;

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

    if (idEndereco) {
      await db.query(
        `UPDATE endereco SET Cidade = ? WHERE IdEndereco = ?`,
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

// SALVAR PLANO DO CUIDADOR
router.put('/:id/plano', async (req, res) => {
  try {
    const { id } = req.params;
    const { plano } = req.body;

    if (!plano) {
      return res.status(400).json({
        success: false,
        message: 'Plano não informado'
      });
    }

    await db.query(
      'UPDATE cuidador SET PlanoAtual = ? WHERE IdCuidador = ?',
      [plano, id]
    );

    return res.json({
      success: true,
      message: 'Plano atualizado com sucesso'
    });
  } catch (error) {
    console.error('Erro ao salvar plano:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao salvar plano',
      error: error.message
    });
  }
});

// BUSCAR PLANO DO CUIDADOR
router.get('/:id/plano', async (req, res) => {
  try {
    const { id } = req.params;

    const rowsResult = await db.query(
      'SELECT PlanoAtual FROM cuidador WHERE IdCuidador = ?',
      [id]
    );
    const rows = normalizeRows(rowsResult);

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado'
      });
    }

    return res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Erro ao buscar plano:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar plano',
      error: error.message
    });
  }
});
// Minhas vagas aceitas pelo cuidador logado
router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    if (req.user.tipo !== 'cuidador') {
      return res.status(403).json({
        success: false,
        message: 'Apenas cuidadores podem acessar suas vagas',
      });
    }

    const idCuidador = req.user.id;

    const vagas = await db.query(`
      SELECT
        vc.IdVagaCuidador,
        vc.IdVaga,
        vc.IdCuidador,
        vc.DataAceite,
        v.Titulo,
        v.Descricao,
        v.Cidade,
        v.DataServico,
        v.HoraInicio,
        v.HoraFim,
        v.Valor,
        v.Status,
        r.IdResponsavel,
        r.Nome AS NomeResponsavel,
        r.Email AS EmailResponsavel,
        r.Telefone AS TelefoneResponsavel
      FROM vagacuidador vc
      INNER JOIN vaga v ON v.IdVaga = vc.IdVaga
      INNER JOIN responsavel r ON r.IdResponsavel = v.IdResponsavel
      WHERE vc.IdCuidador = ?
      ORDER BY vc.IdVagaCuidador DESC
    `, [idCuidador]);

    return res.json({
      success: true,
      message: 'Minhas vagas carregadas com sucesso',
      data: vagas,
    });
  } catch (error) {
    console.error('Erro ao buscar vagas aceitas do cuidador:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});
module.exports = router;