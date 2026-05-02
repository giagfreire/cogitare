const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

function normalizarPlano(nome) {
  const texto = (nome || '').toString().toLowerCase();

  if (texto.includes('premium')) return 'Premium';
  if (texto.includes('basico') || texto.includes('básico')) return 'Básico';

  return 'Gratuito';
}

function limitePorPlano(plano) {
  const planoNormalizado = normalizarPlano(plano);

  if (planoNormalizado === 'Premium') return 20;
  if (planoNormalizado === 'Básico') return 5;

  return 0;
}

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
      fotoUrl,
      sexo,
      escolaridade,
      experienciaProfissional,
      trabalhosFeitos,
      diplomasCertificados,
    } = req.body;

    if (!nome || !email || !senha || !telefone || !cpf) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando',
      });
    }

    const senhaForte =
      senha.length >= 8 &&
      /[A-Z]/.test(senha) &&
      /[a-z]/.test(senha) &&
      /[0-9]/.test(senha);

    if (!senhaForte) {
      return res.status(400).json({
        success: false,
        message:
          'A senha deve ter no mínimo 8 caracteres, com letra maiúscula, minúscula e número.',
      });
    }

    const emailExistente = await db.query(
      'SELECT IdCuidador FROM cuidador WHERE Email = ? LIMIT 1',
      [email]
    );

    if (emailExistente && emailExistente.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Este e-mail já está cadastrado.',
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
      (
        IdEndereco, Nome, Email, Senha, Telefone, Cpf, DataNascimento,
        FotoUrl, Biografia, Fumante, TemFilhos, PossuiCNH, TemCarro,
        UsosPlano, PlanoAtual, Sexo, Escolaridade, ExperienciaProfissional,
        TrabalhosFeitos, DiplomasCertificados
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'Gratuito', ?, ?, ?, ?, ?)`,
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
        sexo || null,
        escolaridade || null,
        experienciaProfissional || null,
        trabalhosFeitos || null,
        diplomasCertificados || null,
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Cuidador cadastrado com sucesso',
      data: {
        idCuidador: result.insertId,
        PlanoAtual: 'Gratuito',
        UsosPlano: 0,
        LimitePlano: 0,
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
      `
      SELECT
        v.IdVaga,
        v.IdResponsavel,
        v.IdIdoso,
        v.Titulo,
        v.Descricao,
        v.Cep,
        v.Cidade,
        v.Bairro,
        v.Rua,
        v.DataServico,
        v.HoraInicio,
        v.HoraFim,
        v.Valor,
        v.Status,
        v.DataCriacao,

        r.Nome AS NomeResponsavel,

        i.Nome AS NomeIdoso,
        i.DataNascimento AS DataNascimentoIdoso,
        i.Sexo AS SexoIdoso,
        i.CuidadosMedicos,
        i.DescricaoExtra,
        i.IdMobilidade AS Mobilidade,
        i.IdNivelAutonomia AS NivelAutonomia

      FROM vaga v
      INNER JOIN responsavel r ON v.IdResponsavel = r.IdResponsavel
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      WHERE v.Status = 'Aberta'
      ORDER BY v.IdVaga DESC
      `
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
 * VISUALIZAR VAGA
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

  let connection;

  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    const [vaga] = await connection.execute(
      'SELECT * FROM vaga WHERE IdVaga = ? LIMIT 1',
      [idVaga]
    );

    if (!vaga || vaga.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada',
      });
    }

    if (vaga[0].Status !== 'Aberta') {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Essa vaga não está mais disponível',
      });
    }

    const [existe] = await connection.execute(
      'SELECT * FROM vagacuidador WHERE IdVaga = ? AND IdCuidador = ? LIMIT 1',
      [idVaga, idCuidador]
    );

    if (existe && existe.length > 0) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Você já visualizou essa vaga',
      });
    }

    const [assinaturaAtiva] = await connection.execute(
      `SELECT
        a.IdAssinatura,
        a.IdPlano,
        COALESCE(a.ContatosUsados, 0) AS ContatosUsados,
        p.Nome AS PlanoAtual,
        COALESCE(p.LimiteContatos, 0) AS LimitePlano
       FROM assinaturacuidador a
       LEFT JOIN plano p ON p.IdPlano = a.IdPlano
       WHERE a.IdCuidador = ?
         AND a.Status = 'Ativa'
       ORDER BY a.IdAssinatura DESC
       LIMIT 1`,
      [idCuidador]
    );

    let planoAtual = 'Gratuito';
    let usosPlano = 0;
    let limitePlano = 0;
    let usaAssinatura = false;
    let idAssinatura = null;

    if (assinaturaAtiva && assinaturaAtiva.length > 0) {
      usaAssinatura = true;
      idAssinatura = assinaturaAtiva[0].IdAssinatura;
      planoAtual = normalizarPlano(assinaturaAtiva[0].PlanoAtual);
      usosPlano = Number(assinaturaAtiva[0].ContatosUsados) || 0;
      limitePlano =
        Number(assinaturaAtiva[0].LimitePlano) || limitePorPlano(planoAtual);
    } else {
      const [cuidador] = await connection.execute(
        `SELECT
          IdCuidador,
          COALESCE(UsosPlano, 0) AS UsosPlano,
          COALESCE(PlanoAtual, 'Gratuito') AS PlanoAtual
         FROM cuidador
         WHERE IdCuidador = ?
         LIMIT 1`,
        [idCuidador]
      );

      if (!cuidador || cuidador.length === 0) {
        await connection.rollback();
        return res.status(404).json({
          success: false,
          message: 'Cuidador não encontrado',
        });
      }

      planoAtual = normalizarPlano(cuidador[0].PlanoAtual);
      usosPlano = Number(cuidador[0].UsosPlano) || 0;
      limitePlano = limitePorPlano(planoAtual);
    }

    if (planoAtual === 'Gratuito' || limitePlano <= 0) {
      await connection.rollback();
      return res.status(403).json({
        success: false,
        message: 'Você está no Plano Gratuito. Escolha um plano para visualizar vagas.',
        data: {
          PlanoAtual: 'Gratuito',
          UsosPlano: 0,
          LimitePlano: 0,
        },
      });
    }

    if (usosPlano >= limitePlano) {
      await connection.rollback();
      return res.status(403).json({
        success: false,
        message:
          planoAtual === 'Premium'
            ? 'Você atingiu o limite do seu plano atual.'
            : 'Você atingiu o limite do Plano Básico. Faça upgrade para Premium.',
        data: {
          PlanoAtual: planoAtual,
          UsosPlano: usosPlano,
          LimitePlano: limitePlano,
        },
      });
    }

    await connection.execute(
      `INSERT INTO vagacuidador (IdVaga, IdCuidador, DataAceite)
       VALUES (?, ?, NOW())`,
      [idVaga, idCuidador]
    );

    if (usaAssinatura && idAssinatura) {
      await connection.execute(
        `UPDATE assinaturacuidador
         SET ContatosUsados = COALESCE(ContatosUsados, 0) + 1
         WHERE IdAssinatura = ?`,
        [idAssinatura]
      );
    } else {
      await connection.execute(
        `UPDATE cuidador
         SET UsosPlano = COALESCE(UsosPlano, 0) + 1
         WHERE IdCuidador = ?`,
        [idCuidador]
      );
    }

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: 'Vaga visualizada com sucesso',
      data: {
        PlanoAtual: planoAtual,
        UsosPlano: usosPlano + 1,
        LimitePlano: limitePlano,
      },
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }

    console.error('ERRO AO VISUALIZAR VAGA:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message,
    });
  } finally {
    if (connection) connection.release();
  }
});

/**
 * MINHAS VAGAS VISUALIZADAS
 */
router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const idCuidador = req.user.id;

    const rows = await db.query(
      `
      SELECT
        vc.IdVagaCuidador,
        vc.IdVaga,
        vc.IdCuidador,
        vc.DataAceite,

        v.IdResponsavel,
        v.IdIdoso,
        v.Titulo,
        v.Descricao,
        v.Cep,
        v.Cidade,
        v.Bairro,
        v.Rua,
        v.DataServico,
        v.HoraInicio,
        v.HoraFim,
        v.Valor,
        v.Status,
        v.WhatsappContato,

        r.Nome AS NomeResponsavel,
        r.Telefone AS TelefoneResponsavel,
        r.Email AS EmailResponsavel,

        i.Nome AS NomeIdoso,
        i.DataNascimento AS DataNascimentoIdoso,
        i.Sexo AS SexoIdoso,
        i.CuidadosMedicos,
        i.DescricaoExtra,
        i.IdMobilidade AS Mobilidade,
        i.IdNivelAutonomia AS NivelAutonomia

      FROM vagacuidador vc
      INNER JOIN vaga v ON v.IdVaga = vc.IdVaga
      INNER JOIN responsavel r ON r.IdResponsavel = v.IdResponsavel
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      WHERE vc.IdCuidador = ?
      ORDER BY vc.IdVagaCuidador DESC
      `,
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
      message: 'Erro ao buscar vagas visualizadas',
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

    const assinaturaAtiva = await db.query(
      `SELECT
        a.IdAssinatura,
        COALESCE(a.ContatosUsados, 0) AS UsosPlano,
        COALESCE(p.Nome, 'Premium') AS PlanoAtual,
        COALESCE(p.LimiteContatos, 20) AS LimitePlano
      FROM assinaturacuidador a
      LEFT JOIN plano p ON p.IdPlano = a.IdPlano
      WHERE a.IdCuidador = ?
        AND a.Status = 'Ativa'
      ORDER BY a.IdAssinatura DESC
      LIMIT 1`,
      [idCuidador]
    );

    if (assinaturaAtiva && assinaturaAtiva.length > 0) {
      const row = assinaturaAtiva[0];
      const planoAtual = normalizarPlano(row.PlanoAtual);

      return res.status(200).json({
        success: true,
        data: {
          PlanoAtual: planoAtual,
          UsosPlano: Number(row.UsosPlano) || 0,
          LimitePlano: Number(row.LimitePlano) || limitePorPlano(planoAtual),
        },
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: 'Gratuito',
        UsosPlano: 0,
        LimitePlano: 0,
      },
    });
  } catch (error) {
    console.error('ERRO STATUS PLANO:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar status do plano',
      error: error.message,
    });
  }
});

/**
 * ATUALIZAR FOTO DO CUIDADOR
 */
router.put('/foto', authenticateToken, async (req, res) => {
  try {
    const idCuidador = req.user.id;
    const { fotoUrl } = req.body;

    if (!fotoUrl || fotoUrl.toString().trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Foto é obrigatória',
      });
    }

    await db.query(
      `UPDATE cuidador
       SET FotoUrl = ?
       WHERE IdCuidador = ?`,
      [fotoUrl, idCuidador]
    );

    return res.status(200).json({
      success: true,
      message: 'Foto atualizada com sucesso',
      data: { fotoUrl },
    });
  } catch (error) {
    console.error('ERRO AO ATUALIZAR FOTO DO CUIDADOR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar foto',
      error: error.message,
    });
  }
});

/**
 * PLANO DO CUIDADOR POR ID
 */
router.get('/:id/plano', async (req, res) => {
  try {
    const { id } = req.params;

    const cuidadorRows = await db.query(
      `SELECT COALESCE(PlanoAtual, 'Gratuito') AS PlanoAtual,
              COALESCE(UsosPlano, 0) AS UsosPlano
       FROM cuidador
       WHERE IdCuidador = ?
       LIMIT 1`,
      [id]
    );

    if (!cuidadorRows || cuidadorRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado',
      });
    }

    const assinaturaAtiva = await db.query(
      `SELECT
        a.IdAssinatura,
        COALESCE(a.ContatosUsados, 0) AS UsosPlano,
        COALESCE(p.Nome, 'Premium') AS PlanoAtual,
        COALESCE(p.LimiteContatos, 20) AS LimitePlano
      FROM assinaturacuidador a
      LEFT JOIN plano p ON p.IdPlano = a.IdPlano
      WHERE a.IdCuidador = ?
        AND a.Status = 'Ativa'
      ORDER BY a.IdAssinatura DESC
      LIMIT 1`,
      [id]
    );

    if (assinaturaAtiva && assinaturaAtiva.length > 0) {
      const row = assinaturaAtiva[0];
      const planoAtual = normalizarPlano(row.PlanoAtual);

      return res.status(200).json({
        success: true,
        data: {
          PlanoAtual: planoAtual,
          UsosPlano: Number(row.UsosPlano) || 0,
          LimitePlano: Number(row.LimitePlano) || limitePorPlano(planoAtual),
        },
      });
    }

    const cuidador = cuidadorRows[0];
    const planoAtual = normalizarPlano(cuidador.PlanoAtual);

    return res.status(200).json({
      success: true,
      data: {
        PlanoAtual: planoAtual,
        UsosPlano: planoAtual === 'Gratuito' ? 0 : Number(cuidador.UsosPlano) || 0,
        LimitePlano: limitePorPlano(planoAtual),
      },
    });
  } catch (error) {
    console.error('ERRO PLANO:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar plano',
      error: error.message,
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
        c.IdEndereco AS idEndereco,
        c.Sexo AS sexo,
        c.Escolaridade AS escolaridade,
        c.ExperienciaProfissional AS experienciaProfissional,
        c.TrabalhosFeitos AS trabalhosFeitos,
        c.DiplomasCertificados AS diplomasCertificados,
        COALESCE(c.UsosPlano, 0) AS usosPlano,
        COALESCE(c.PlanoAtual, 'Gratuito') AS planoAtual,
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
 * ATUALIZAR CUIDADOR
 */
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    if (Number(req.user.id) !== Number(id)) {
      return res.status(403).json({
        success: false,
        message: 'Você não tem permissão para editar este perfil.',
      });
    }

    const {
      nome,
      telefone,
      cpf,
      dataNascimento,
      sexo,
      cidade,
      biografia,
      fotoUrl,
      escolaridade,
      experienciaProfissional,
      trabalhosFeitos,
      diplomasCertificados,
    } = req.body;

    const cuidador = await db.query(
      'SELECT IdEndereco FROM cuidador WHERE IdCuidador = ? LIMIT 1',
      [id]
    );

    if (!cuidador || cuidador.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cuidador não encontrado',
      });
    }

    const campos = [
      'Nome = ?',
      'Telefone = ?',
      'Cpf = ?',
      'DataNascimento = ?',
      'Sexo = ?',
      'Biografia = ?',
      'Escolaridade = ?',
      'ExperienciaProfissional = ?',
      'TrabalhosFeitos = ?',
      'DiplomasCertificados = ?',
    ];

    const valores = [
      nome || null,
      telefone || null,
      cpf || null,
      dataNascimento || null,
      sexo || null,
      biografia || null,
      escolaridade || null,
      experienciaProfissional || null,
      trabalhosFeitos || null,
      diplomasCertificados || null,
    ];

    if (fotoUrl) {
      campos.push('FotoUrl = ?');
      valores.push(fotoUrl);
    }

    valores.push(id);

    await db.query(
      `UPDATE cuidador
       SET ${campos.join(', ')}
       WHERE IdCuidador = ?`,
      valores
    );

    if (cidade && cuidador[0].IdEndereco) {
      await db.query(
        `UPDATE endereco
         SET Cidade = ?
         WHERE IdEndereco = ?`,
        [cidade, cuidador[0].IdEndereco]
      );
    }

    if (cidade && !cuidador[0].IdEndereco) {
      const enderecoResult = await db.query(
        `INSERT INTO endereco (Cidade)
         VALUES (?)`,
        [cidade]
      );

      await db.query(
        `UPDATE cuidador
         SET IdEndereco = ?
         WHERE IdCuidador = ?`,
        [enderecoResult.insertId, id]
      );
    }

    return res.status(200).json({
      success: true,
      message: 'Perfil atualizado com sucesso',
    });
  } catch (error) {
    console.error('ERRO PUT CUIDADOR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar perfil',
      error: error.message,
    });
  }
});

module.exports = router;