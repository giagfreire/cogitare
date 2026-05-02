const express = require('express');
const bcrypt = require('bcryptjs');
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

router.post('/completo', async (req, res) => {
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

    if (!nome || !email || !senha || !cpf || !telefone || !dataNascimento) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando',
      });
    }

    const nascimento = new Date(dataNascimento);
    const hoje = new Date();
    const idade = hoje.getFullYear() - nascimento.getFullYear();

    if (idade < 18) {
      return res.status(400).json({
        success: false,
        message: 'Você precisa ser maior de 18 anos',
      });
    }

    const senhaForte = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;

    if (!senhaForte.test(senha)) {
      return res.status(400).json({
        success: false,
        message:
          'Senha fraca. Use 8+ caracteres com maiúscula, minúscula, número e símbolo.',
      });
    }

    const existeEmail = await db.query(
      `SELECT IdResponsavel FROM responsavel WHERE Email = ?`,
      [email]
    );

    if (existeEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'E-mail já cadastrado',
      });
    }

    const enderecoResult = await db.query(
      `
      INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [cidade, bairro, rua, numero, complemento || null, cep]
    );

    const idEndereco = enderecoResult.insertId;
    const senhaHash = await bcrypt.hash(senha, 10);

    const result = await db.query(
      `
      INSERT INTO responsavel
      (IdEndereco, Nome, Email, Senha, Telefone, Cpf, DataNascimento, FotoUrl)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        idEndereco,
        nome,
        email,
        senhaHash,
        telefone,
        cpf,
        dataNascimento,
        fotoUrl || null,
      ]
    );

    return res.json({
      success: true,
      message: 'Cadastro realizado com sucesso',
      guardianId: result.insertId,
    });
  } catch (error) {
    console.error('ERRO CADASTRO COMPLETO:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao cadastrar responsável',
      error: error.message,
    });
  }
});

/* =========================
   PERFIL RESPONSÁVEL
========================= */

router.get('/perfil', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const resultado = await db.query(
      `
      SELECT
        r.IdResponsavel,
        r.Nome,
        r.Email,
        r.Telefone,
        r.Cpf,
        r.DataNascimento,
        r.FotoUrl,
        r.IdEndereco,

        e.Cidade,
        e.Bairro,
        e.Rua,
        e.Numero,
        e.Complemento,
        e.Cep,

        r.Nome AS nome,
        r.Email AS email,
        r.Telefone AS telefone,
        r.Cpf AS cpf,
        r.DataNascimento AS dataNascimento,
        r.FotoUrl AS fotoUrl,

        e.Cidade AS cidade,
        e.Bairro AS bairro,
        e.Rua AS rua,
        e.Numero AS numero,
        e.Complemento AS complemento,
        e.Cep AS cep
      FROM responsavel r
      LEFT JOIN endereco e ON e.IdEndereco = r.IdEndereco
      WHERE r.IdResponsavel = ?
      LIMIT 1
      `,
      [idResponsavel]
    );

    const rows = normalizarRows(resultado);

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado.',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('ERRO BUSCAR PERFIL RESPONSÁVEL:', error);

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

    const {
      nome,
      email,
      telefone,
      dataNascimento,
      fotoUrl,
      cep,
      cidade,
      bairro,
      rua,
      numero,
      complemento,
    } = req.body;

    if (!nome || !email || !telefone || !dataNascimento) {
      return res.status(400).json({
        success: false,
        message: 'Nome, e-mail, telefone e data de nascimento são obrigatórios.',
      });
    }

    const responsavelRows = await db.query(
      `SELECT IdEndereco FROM responsavel WHERE IdResponsavel = ? LIMIT 1`,
      [idResponsavel]
    );

    const responsavel = normalizarRows(responsavelRows)[0];

    if (!responsavel) {
      return res.status(404).json({
        success: false,
        message: 'Responsável não encontrado.',
      });
    }

    const camposResponsavel = [
      'Nome = ?',
      'Email = ?',
      'Telefone = ?',
      'DataNascimento = ?',
    ];

    const valoresResponsavel = [nome, email, telefone, dataNascimento];

    if (fotoUrl !== undefined && fotoUrl !== null && fotoUrl !== '') {
      camposResponsavel.push('FotoUrl = ?');
      valoresResponsavel.push(fotoUrl);
    }

    valoresResponsavel.push(idResponsavel);

    await db.query(
      `
      UPDATE responsavel
      SET ${camposResponsavel.join(', ')}
      WHERE IdResponsavel = ?
      `,
      valoresResponsavel
    );

    const temEndereco =
      cep || cidade || bairro || rua || numero || complemento;

    if (temEndereco) {
      if (responsavel.IdEndereco) {
        await db.query(
          `
          UPDATE endereco
          SET
            Cidade = ?,
            Bairro = ?,
            Rua = ?,
            Numero = ?,
            Complemento = ?,
            Cep = ?
          WHERE IdEndereco = ?
          `,
          [
            cidade || null,
            bairro || null,
            rua || null,
            numero || null,
            complemento || null,
            cep || null,
            responsavel.IdEndereco,
          ]
        );
      } else {
        const enderecoResult = await db.query(
          `
          INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            cidade || null,
            bairro || null,
            rua || null,
            numero || null,
            complemento || null,
            cep || null,
          ]
        );

        await db.query(
          `
          UPDATE responsavel
          SET IdEndereco = ?
          WHERE IdResponsavel = ?
          `,
          [enderecoResult.insertId, idResponsavel]
        );
      }
    }

    return res.json({
      success: true,
      message: 'Perfil atualizado com sucesso.',
    });
  } catch (error) {
    console.error('ERRO ATUALIZAR PERFIL RESPONSÁVEL:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar perfil.',
      error: error.message,
    });
  }
});

/* =========================
   CRIAR VAGA SEM DATA/HORA/VALOR
========================= */

router.post('/vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const {
      idIdoso,
      titulo,
      descricao,
      cep,
      cidade,
      bairro,
      rua,
      whatsappContato,
    } = req.body;

    if (!titulo || !cidade) {
      return res.status(400).json({
        success: false,
        message: 'Título e cidade são obrigatórios.',
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
        Status,
        WhatsappContato
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Aberta', ?)
      `,
      [
        idResponsavel,
        idIdoso || null,
        titulo,
        descricao || 'Sem descrição',
        cep || null,
        cidade,
        bairro || null,
        rua || null,
        whatsappContato || null,
      ]
    );

    return res.json({
      success: true,
      message: 'Vaga criada com sucesso',
      data: { idVaga: result.insertId },
    });
  } catch (error) {
    console.error('ERRO CRIAR VAGA:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao criar vaga',
      error: error.message,
    });
  }
});

router.put('/vaga/:id', authenticateToken, async (req, res) => {
  try {
    const idVaga = req.params.id;
    const idResponsavel = getResponsavelId(req);

    const {
      titulo,
      descricao,
      cep,
      cidade,
      bairro,
      rua,
      whatsappContato,
    } = req.body;

    if (!titulo || !cidade) {
      return res.status(400).json({
        success: false,
        message: 'Título e cidade são obrigatórios.',
      });
    }

    await db.query(
      `
      UPDATE vaga
      SET
        Titulo = ?,
        Descricao = ?,
        Cep = ?,
        Cidade = ?,
        Bairro = ?,
        Rua = ?,
        WhatsappContato = ?
      WHERE IdVaga = ? AND IdResponsavel = ?
      `,
      [
        titulo,
        descricao || 'Sem descrição',
        cep || null,
        cidade,
        bairro || null,
        rua || null,
        whatsappContato || null,
        idVaga,
        idResponsavel,
      ]
    );

    return res.json({
      success: true,
      message: 'Vaga atualizada com sucesso.',
    });
  } catch (error) {
    console.error('ERRO EDITAR VAGA:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao editar vaga.',
      error: error.message,
    });
  }
});

/* =========================
   MINHAS VAGAS
========================= */

router.get('/minhas-vagas', authenticateToken, async (req, res) => {
  try {
    const idResponsavel = getResponsavelId(req);

    const resultado = await db.query(
      `
      SELECT 
        v.*,
        i.Nome AS NomeIdoso,
        COUNT(vc.IdVagaCuidador) AS TotalInteressados
      FROM vaga v
      LEFT JOIN idoso i ON i.IdIdoso = v.IdIdoso
      LEFT JOIN vagacuidador vc ON vc.IdVaga = v.IdVaga
      WHERE v.IdResponsavel = ?
      GROUP BY v.IdVaga
      ORDER BY v.IdVaga DESC
      `,
      [idResponsavel]
    );

    return res.json({
      success: true,
      data: normalizarRows(resultado),
    });
  } catch (error) {
    console.error('ERRO MINHAS VAGAS:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao listar vagas',
      error: error.message,
    });
  }
});

router.delete('/vaga/:id', authenticateToken, async (req, res) => {
  try {
    const idVaga = req.params.id;
    const idResponsavel = getResponsavelId(req);

    await db.query(
      `DELETE FROM vagacuidador WHERE IdVaga = ?`,
      [idVaga]
    );

    await db.query(
      `DELETE FROM vaga WHERE IdVaga = ? AND IdResponsavel = ?`,
      [idVaga, idResponsavel]
    );

    return res.json({
      success: true,
      message: 'Vaga excluída com sucesso',
    });
  } catch (error) {
    console.error('ERRO EXCLUIR VAGA:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao excluir vaga',
      error: error.message,
    });
  }
});

router.put('/vaga/:id/status', authenticateToken, async (req, res) => {
  try {
    const idVaga = req.params.id;
    const idResponsavel = getResponsavelId(req);
    const { status } = req.body;

    if (!status || !['Aberta', 'Interrompida', 'Encerrada'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status inválido.',
      });
    }

    await db.query(
      `
      UPDATE vaga
      SET Status = ?
      WHERE IdVaga = ? AND IdResponsavel = ?
      `,
      [status, idVaga, idResponsavel]
    );

    return res.json({
      success: true,
      message: 'Status da vaga atualizado',
    });
  } catch (error) {
    console.error('ERRO ALTERAR STATUS:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao alterar status da vaga',
      error: error.message,
    });
  }
});

module.exports = router;