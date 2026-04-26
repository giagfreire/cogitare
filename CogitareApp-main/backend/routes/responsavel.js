const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
const bcrypt = require('bcryptjs');

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
      fotoUrl
    } = req.body;

    // ========================
    // VALIDAÇÕES
    // ========================

    if (!nome || !email || !senha || !cpf || !telefone || !dataNascimento) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando'
      });
    }

    // 👉 IDADE (18+)
    const nascimento = new Date(dataNascimento);
    const hoje = new Date();
    const idade = hoje.getFullYear() - nascimento.getFullYear();

    if (idade < 18) {
      return res.status(400).json({
        success: false,
        message: 'Você precisa ser maior de 18 anos'
      });
    }

    // 👉 SENHA FORTE
    const senhaForte =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;

    if (!senhaForte.test(senha)) {
      return res.status(400).json({
        success: false,
        message:
          'Senha fraca. Use 8+ caracteres com maiúscula, minúscula, número e símbolo.'
      });
    }

    // 👉 EMAIL DUPLICADO
    const existeEmail = await db.query(
      `SELECT IdResponsavel FROM responsavel WHERE Email = ?`,
      [email]
    );

    if (existeEmail.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'E-mail já cadastrado'
      });
    }

    // ========================
    // CRIAR ENDEREÇO
    // ========================

    const enderecoResult = await db.query(
      `
      INSERT INTO endereco (Cidade, Bairro, Rua, Numero, Complemento, Cep)
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [cidade, bairro, rua, numero, complemento, cep]
    );

    const idEndereco = enderecoResult.insertId;

    // ========================
    // CRIAR RESPONSÁVEL
    // ========================

    const bcrypt = require('bcryptjs');
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
        fotoUrl || null
      ]
    );

    return res.json({
      success: true,
      message: 'Cadastro realizado com sucesso',
      guardianId: result.insertId
    });

  } catch (error) {
    console.error('ERRO CADASTRO COMPLETO:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao cadastrar responsável'
    });
  }
});

/* =========================
   CRIAR VAGA (CORRIGIDO)
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
      dataServico,
      horaInicio,
      horaFim,
      valor,
      whatsappContato
    } = req.body;

    if (!titulo || !cidade || !dataServico || !horaInicio || !horaFim || !whatsappContato) {
      return res.status(400).json({
        success: false,
        message: 'Campos obrigatórios faltando (incluindo WhatsApp)',
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
        Status,
        WhatsappContato
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Aberta', ?)
      `,
      [
        idResponsavel,
        idIdoso,
        titulo,
        descricao || 'Sem descrição',
        cep,
        cidade,
        bairro,
        rua,
        dataServico,
        horaInicio,
        horaFim,
        valor || 0,
        whatsappContato
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
    });
  }
});

/* =========================
   MINHAS VAGAS (COM WHATSAPP)
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
    });
  }
});

/* =========================
   EXCLUIR VAGA (FIX)
========================= */

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
    });
  }
});

module.exports = router;