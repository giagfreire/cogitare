const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

function getResponsavelId(req) {
  return req.user?.id || req.user?.IdResponsavel || req.user?.userId;
}

function normalizarRows(resultado) {
  if (Array.isArray(resultado)) return resultado;
  if (resultado && Array.isArray(resultado.rows)) return resultado.rows;
  return resultado ? [resultado] : [];
}

/* PERFIL DO RESPONSÁVEL */
router.get('/perfil', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    if (!idResponsavel) {
      return res.status(401).json({
        success: false,
        message: 'ID do responsável não encontrado no token.',
      });
    }

    const resultado = await db.query(
      `
      SELECT 
        IdResponsavel,
        Nome,
        Email,
        Telefone,
        Cpf,
        DataNascimento,
        FotoUrl
      FROM responsavel
      WHERE IdResponsavel = ?
      LIMIT 1
      `,
      [idResponsavel]
    );

    const rows = normalizarRows(resultado);
    const perfil = rows[0];

    if (!perfil) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado.',
      });
    }

    return res.json({
      success: true,
      data: perfil,
    });
  } catch (error) {
    console.error('Erro ao buscar perfil do responsável:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar perfil.',
      error: error.message,
    });
  }
});

router.put('/perfil', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    if (!idResponsavel) {
      return res.status(401).json({
        success: false,
        message: 'ID do responsável não encontrado no token.',
      });
    }

    const { nome, email, telefone, dataNascimento, fotoUrl } = req.body;

    if (!nome || !email || !telefone) {
      return res.status(400).json({
        success: false,
        message: 'Nome, email e telefone são obrigatórios.',
      });
    }

    const result = await db.query(
      `
      UPDATE responsavel
      SET 
        Nome = ?,
        Email = ?,
        Telefone = ?,
        DataNascimento = ?,
        FotoUrl = ?
      WHERE IdResponsavel = ?
      `,
      [
        nome,
        email,
        telefone,
        dataNascimento || null,
        fotoUrl || null,
        idResponsavel,
      ]
    );

    if (result && result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado para atualizar.',
      });
    }

    const resultadoPerfil = await db.query(
      `
      SELECT 
        IdResponsavel,
        Nome,
        Email,
        Telefone,
        Cpf,
        DataNascimento,
        FotoUrl
      FROM responsavel
      WHERE IdResponsavel = ?
      LIMIT 1
      `,
      [idResponsavel]
    );

    const rows = normalizarRows(resultadoPerfil);

    return res.json({
      success: true,
      message: 'Perfil atualizado com sucesso.',
      data: rows[0],
    });
  } catch (error) {
    console.error('Erro ao atualizar perfil do responsável:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar perfil.',
      error: error.message,
    });
  }
});

/* CRIAR VAGA */
router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    if (!idResponsavel) {
      return res.status(401).json({
        success: false,
        message: 'ID do responsável não encontrado no token.',
      });
    }

    const {
      idIdoso,
      titulo,
      cep,
      cidade,
      bairro,
      rua,
      dataServico,
      horaInicio,
      horaFim,
    } = req.body;

    if (
      !idIdoso ||
      !titulo ||
      !cep ||
      !cidade ||
      !dataServico ||
      !horaInicio ||
      !horaFim
    ) {
      return res.status(400).json({
        success: false,
        message: 'Preencha idoso, título, localidade, data e horários.',
      });
    }

    const result = await db.query(
      `
      INSERT INTO vaga
      (
        IdResponsavel,
        IdIdoso,
        Titulo,
        Descricao,
        Cep,
        Cidade,
        Bairro,
        Rua,
        DataServico,
        HoraInicio,
        HoraFim,
        Valor,
        Status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        idResponsavel,
        idIdoso,
        titulo,
        'Valor a combinar com o cuidador.',
        cep,
        cidade,
        bairro || null,
        rua || null,
        dataServico,
        horaInicio,
        horaFim,
        0,
        'Aberta',
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Vaga criada com sucesso.',
      data: { idVaga: result.insertId },
    });
  } catch (error) {
    console.error('Erro ao criar vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao criar vaga.',
      error: error.message,
    });
  }
});

/* MINHAS VAGAS */
router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    if (!idResponsavel) {
      return res.status(401).json({
        success: false,
        message: 'ID do responsável não encontrado no token.',
      });
    }

    const resultado = await db.query(
      `
      SELECT 
        v.*,
        i.Nome AS NomeIdoso,
        COALESCE(COUNT(iv.IdInteresse), 0) AS TotalInteressados
      FROM vaga v
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      LEFT JOIN interesse_vaga iv ON iv.IdVaga = v.IdVaga
      WHERE v.IdResponsavel = ?
      GROUP BY v.IdVaga
      ORDER BY v.DataCriacao DESC
      `,
      [idResponsavel]
    );

    return res.json({
      success: true,
      data: normalizarRows(resultado),
    });
  } catch (error) {
    console.error('Erro ao listar minhas vagas:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao listar minhas vagas.',
      error: error.message,
    });
  }
});

/* BUSCAR UMA VAGA */
router.get('/vaga/:idVaga', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);
    const { idVaga } = req.params;

    const resultado = await db.query(
      `
      SELECT 
        v.*,
        i.Nome AS NomeIdoso
      FROM vaga v
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      WHERE v.IdVaga = ? AND v.IdResponsavel = ?
      LIMIT 1
      `,
      [idVaga, idResponsavel]
    );

    const rows = normalizarRows(resultado);

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada.',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('Erro ao buscar vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar vaga.',
      error: error.message,
    });
  }
});

/* EDITAR VAGA */
router.put('/vaga/:idVaga', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);
    const { idVaga } = req.params;

    const {
      titulo,
      cep,
      cidade,
      bairro,
      rua,
      dataServico,
      horaInicio,
      horaFim,
    } = req.body;

    if (!titulo || !cep || !cidade || !dataServico || !horaInicio || !horaFim) {
      return res.status(400).json({
        success: false,
        message: 'Preencha título, localidade, data e horários.',
      });
    }

    const result = await db.query(
      `
      UPDATE vaga
      SET 
        Titulo = ?,
        Cep = ?,
        Cidade = ?,
        Bairro = ?,
        Rua = ?,
        DataServico = ?,
        HoraInicio = ?,
        HoraFim = ?
      WHERE IdVaga = ? AND IdResponsavel = ?
      `,
      [
        titulo,
        cep,
        cidade,
        bairro || null,
        rua || null,
        dataServico,
        horaInicio,
        horaFim,
        idVaga,
        idResponsavel,
      ]
    );

    if (result && result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada para este responsável.',
      });
    }

    return res.json({
      success: true,
      message: 'Vaga atualizada com sucesso.',
    });
  } catch (error) {
    console.error('Erro ao editar vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao editar vaga.',
      error: error.message,
    });
  }
});

/* ENCERRAR / REABRIR VAGA */
router.put('/vaga/:idVaga/status', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);
    const { idVaga } = req.params;
    const { status } = req.body;

    if (!['Aberta', 'Encerrada'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status inválido. Use Aberta ou Encerrada.',
      });
    }

    const result = await db.query(
      `
      UPDATE vaga
      SET Status = ?
      WHERE IdVaga = ? AND IdResponsavel = ?
      `,
      [status, idVaga, idResponsavel]
    );

    if (result && result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada para este responsável.',
      });
    }

    return res.json({
      success: true,
      message: status === 'Aberta' ? 'Vaga reaberta.' : 'Vaga encerrada.',
    });
  } catch (error) {
    console.error('Erro ao alterar status da vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao alterar status da vaga.',
      error: error.message,
    });
  }
});

/* EXCLUIR VAGA */
router.delete('/vaga/:idVaga', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);
    const { idVaga } = req.params;

    const result = await db.query(
      `
      DELETE FROM vaga
      WHERE IdVaga = ? AND IdResponsavel = ?
      `,
      [idVaga, idResponsavel]
    );

    if (result && result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vaga não encontrada para este responsável.',
      });
    }

    return res.json({
      success: true,
      message: 'Vaga excluída com sucesso.',
    });
  } catch (error) {
    console.error('Erro ao excluir vaga:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao excluir vaga.',
      error: error.message,
    });
  }
});

/* VER INTERESSADOS */
router.get('/vaga/:idVaga/interessados', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);
    const { idVaga } = req.params;

    const resultado = await db.query(
      `
      SELECT 
        iv.*,
        c.IdCuidador,
        c.Nome,
        c.Email,
        c.Telefone,
        c.FotoUrl,
        c.Biografia,
        c.ValorHora
      FROM interesse_vaga iv
      INNER JOIN cuidador c ON c.IdCuidador = iv.IdCuidador
      INNER JOIN vaga v ON v.IdVaga = iv.IdVaga
      WHERE iv.IdVaga = ? AND v.IdResponsavel = ?
      ORDER BY iv.DataCriacao DESC
      `,
      [idVaga, idResponsavel]
    );

    return res.json({
      success: true,
      data: normalizarRows(resultado),
    });
  } catch (error) {
    console.error('Erro ao buscar interessados:', error);
    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar interessados.',
      error: error.message,
    });
  }
});

module.exports = router;