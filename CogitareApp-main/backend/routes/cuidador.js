const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

/**
 * CADASTRO CUIDADOR
 */
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
      fotoUrl,
    } = req.body;

    if (!nome || !email || !senha || !telefone || !cpf) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando',
      });
    }

    let idEndereco = null;

    if (cidade && bairro && rua && numero && cep) {
      const enderecoResult = await db.query(
        `INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [cidade, bairro, rua, numero, complemento || null, cep]
      );

      idEndereco = enderecoResult.insertId;
    }

    const senhaHash = await bcrypt.hash(senha, 10);

    const result = await db.query(
      `INSERT INTO cuidador
      (IdEndereco, Nome, Email, Senha, Telefone, Cpf, DataNascimento, FotoUrl, Biografia, Fumante, TemFilhos, PossuiCNH, TemCarro, ValorHora, UsosPlano)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`,
      [
        idEndereco,
        nome,
        email,
        senhaHash,
        telefone,
        cpf,
        dataNascimento || null,
        fotoUrl || null,
        biografia || null,
        fumante || 'Não',
        temFilhos || 'Não',
        possuiCnh || 'Não',
        temCarro || 'Não',
        valorHora || null,
      ]
    );

    return res.status(201).json({
      success: true,
      data: {
        idCuidador: result.insertId,
      },
    });
  } catch (error) {
    console.error('ERRO CADASTRO:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao cadastrar',
      error: error.message,
    });
  }
});

/**
 * VAGAS ABERTAS
 */
router.get('/vagas-abertas', async (req, res) => {
  try {
    const rows = await db.query(
      `SELECT
        v.*,
        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel
       FROM vaga v
       INNER JOIN responsavel r ON v.IdResponsavel = r.IdResponsavel
       WHERE v.Status = 'Aberta'
       ORDER BY v.IdVaga DESC`
    );

    return res.status(200).json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('ERRO VAGAS:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar vagas',
      error: error.message,
    });
  }
});

/**
 * ACEITAR VAGA
 */
router.post('/aceitar-vaga', authenticateToken, async (req, res) => {
  const { idVaga } = req.body;
  const idCuidador = req.user.id;

  if (!idVaga) {
    return res.status(400).json({
      success: false,
      message: 'ID da vaga é obrigatório',
    });
  }

  try {
    const vaga = await db.query(
      'SELECT * FROM vaga WHERE IdVaga = ? LIMIT 1',
      [idVaga]
    );

    if (!vaga || vaga.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada',
      });
    }

    if (vaga[0].Status !== 'Aberta') {
      return res.status(400).json({
        success: false,
        message: 'Essa vaga não está mais disponível',
      });
    }

    const existe = await db.query(
      'SELECT * FROM vagacuidador WHERE IdVaga = ? AND IdCuidador = ?',
      [idVaga, idCuidador]
    );

    if (existe.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Você já aceitou essa vaga',
      });
    }

    await db.query(
      `INSERT INTO vagacuidador (IdVaga, IdCuidador, DataAceite)
       VALUES (?, ?, NOW())`,
      [idVaga, idCuidador]
    );

    await db.query(
      `UPDATE assinaturacuidador
       SET ContatosUsados = COALESCE(ContatosUsados, 0) + 1
       WHERE IdCuidador = ? AND Status = 'Ativa'`,
      [idCuidador]
    );

    return res.status(200).json({
      success: true,
      message: 'Vaga aceita com sucesso',
    });
  } catch (error) {
    console.error('ERRO AO ACEITAR VAGA:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  }
});

/**
 * MINHAS VAGAS ACEITAS
 */
router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const idCuidador = req.user.id;

    const rows = await db.query(
      `SELECT
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
        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel
      FROM vagacuidador vc
      INNER JOIN vaga v ON v.IdVaga = vc.IdVaga
      INNER JOIN responsavel r ON r.IdResponsavel = v.IdResponsavel
      WHERE vc.IdCuidador = ?
      ORDER BY vc.IdVagaCuidador DESC`,
      [idCuidador]
    );

    return res.status(200).json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('ERRO MINHAS VAGAS:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar vagas aceitas',
      error: error.message,
    });
  }
});

/**
 * STATUS DO PLANO DO CUIDADOR LOGADO
 */
router.get('/status-plano', authenticateToken, async (req, res) => {
  try {
    const idCuidador = req.user.id;

    const rows = await db.query(
      `SELECT
        c.IdCuidador,
        COALESCE(a.ContatosUsados, 0) AS UsosPlano,
        COALESCE(p.Nome, 'Basico') AS PlanoAtual,
        COALESCE(p.LimiteContatos, 5) AS LimitePlano
      FROM cuidador c
      LEFT JOIN assinaturacuidador a
        ON a.IdCuidador = c.IdCuidador
       AND a.Status = 'Ativa'
      LEFT JOIN plano p
        ON p.IdPlano = a.IdPlano
      WHERE c.IdCuidador = ?
      LIMIT 1`,
      [idCuidador]
    );

    if (!rows || rows.length === 0 || !rows[0]) {
      return res.status(200).json({
        success: true,
        data: {
          PlanoAtual: 'Basico',
          UsosPlano: 0,
          LimitePlano: 5,
        },
      });
    }

    const row = rows[0];

    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: row.PlanoAtual || 'Basico',
        UsosPlano: Number(row.UsosPlano) || 0,
        LimitePlano: Number(row.LimitePlano) || 5,
      },
    });
  } catch (error) {
    console.error('ERRO STATUS PLANO:', error);
    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: 'Basico',
        UsosPlano: 0,
        LimitePlano: 5,
      },
    });
  }
});

/**
 * PLANO DO CUIDADOR POR ID
 */
router.get('/:id/plano', async (req, res) => {
  try {
    const { id } = req.params;

    const rows = await db.query(
      `SELECT
        c.IdCuidador,
        COALESCE(c.UsosPlano, 0) AS UsosPlano,
        p.Nome AS PlanoAtual,
        p.LimiteContatos
      FROM cuidador c
      LEFT JOIN assinaturacuidador a
        ON a.IdCuidador = c.IdCuidador
       AND a.Status = 'Ativa'
      LEFT JOIN plano p
        ON p.IdPlano = a.IdPlano
      WHERE c.IdCuidador = ?
      LIMIT 1`,
      [id]
    );

    if (!rows || rows.length === 0 || !rows[0]) {
      return res.status(200).json({
        success: true,
        data: {
          PlanoAtual: 'Basico',
          UsosPlano: 0,
          LimitePlano: 5,
        },
      });
    }

    const row = rows[0];
    const plano = row.PlanoAtual || 'Basico';
    const usos = Number(row.UsosPlano) || 0;
    const limite =
      Number(row.LimiteContatos) ||
      (plano.toLowerCase() === 'premium' ? 20 : 5);

    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: plano,
        UsosPlano: usos,
        LimitePlano: limite,
      },
    });
  } catch (error) {
    console.error('ERRO PLANO:', error);
    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: 'Basico',
        UsosPlano: 0,
        LimitePlano: 5,
      },
    });
  }
});

/**
 * BUSCAR CUIDADOR
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const rows = await db.query(
      `SELECT
        c.IdCuidador AS id,
        c.Nome AS nome,
        c.Email AS email,
        c.Telefone AS telefone,
        c.Cpf AS cpf,
        c.DataNascimento AS dataNascimento,
        c.FotoUrl AS fotoUrl,
        c.Biografia AS biografia,
        c.Fumante AS fumante,
        c.TemFilhos AS temFilhos,
        c.PossuiCNH AS possuiCNH,
        c.TemCarro AS temCarro,
        c.ValorHora AS valorHora,
        c.IdEndereco AS idEndereco,
        COALESCE(c.UsosPlano, 0) AS usosPlano,
        e.Cidade AS cidade,
        e.Bairro AS bairro,
        e.Rua AS rua,
        e.Numero AS numero,
        e.Complemento AS complemento,
        e.Cep AS cep
      FROM cuidador c
      LEFT JOIN endereco e ON e.IdEndereco = c.IdEndereco
      WHERE c.IdCuidador = ?
      LIMIT 1`,
      [id]
    );

    console.log('ROWS GET CUIDADOR:', rows);

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado',
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('ERRO GET CUIDADOR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar cuidador',
      error: error.message,
    });
  }
});

/**
 * BUSCAR DISPONIBILIDADE DO CUIDADOR
 */
router.get('/:id/disponibilidade', async (req, res) => {
  try {
    const { id } = req.params;

    const rows = await db.query(
      `SELECT
        IdDisponibilidade,
        IdCuidador,
        DiaSemana,
        DataInicio,
        DataFim,
        Observacoes,
        Recorrente
      FROM disponibilidade
      WHERE IdCuidador = ?
      ORDER BY FIELD(
        DiaSemana,
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado',
        'Domingo'
      )`,
      [id]
    );

    return res.status(200).json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('ERRO GET DISPONIBILIDADE:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar disponibilidade',
      error: error.message,
    });
  }
});

/**
 * SALVAR DISPONIBILIDADE DO CUIDADOR
 */
router.post('/:id/disponibilidade', async (req, res) => {
  let connection;

  try {
    const { id } = req.params;
    const { disponibilidade } = req.body;

    if (!Array.isArray(disponibilidade)) {
      return res.status(400).json({
        success: false,
        message: 'Formato de disponibilidade inválido',
      });
    }

    connection = await db.getConnection();
    await connection.beginTransaction();

    await connection.execute(
      'DELETE FROM disponibilidade WHERE IdCuidador = ?',
      [id]
    );

    for (const item of disponibilidade) {
      const ativo = item.ativo === true;
      const dia = item.dia;
      const inicio = ativo ? item.inicio : null;
      const fim = ativo ? item.fim : null;

      await connection.execute(
        `INSERT INTO disponibilidade
        (IdCuidador, DiaSemana, DataInicio, DataFim, Observacoes, Recorrente)
        VALUES (?, ?, ?, ?, ?, ?)`,
        [id, dia, inicio, fim, null, 1]
      );
    }

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: 'Disponibilidade salva com sucesso',
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }

    console.error('ERRO POST DISPONIBILIDADE:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao salvar disponibilidade',
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

module.exports = router;