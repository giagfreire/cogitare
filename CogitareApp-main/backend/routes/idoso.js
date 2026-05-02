const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

function getResponsavelId(req) {
  return req.user?.id || req.user?.IdResponsavel || req.user?.userId;
}

function normalizarRows(resultado) {
  if (Array.isArray(resultado)) return resultado;
  if (resultado && Array.isArray(resultado.rows)) return resultado.rows;
  return resultado ? [resultado] : [];
}

router.post('/cadastro', authenticateToken, async (req, res) => {
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

const {
  IdResponsavel,
  IdMobilidade,
  IdNivelAutonomia,
  Nome,
  DataNascimento,
  Sexo,
  CuidadosMedicos,
  DescricaoExtra,
  UsaMedicacao,
  MedicacaoDetalhes,
  PrecisaBanho,
  BanhoDetalhes,
  PrecisaAlimentacao,
  AlimentacaoDetalhes,
  PrecisaAcompanhamento,
  AcompanhamentoDetalhes,
  ServicosDetalhados,
} = req.body;

    const idResponsavelFinal = IdResponsavel || getResponsavelId(req);

    if (!idResponsavelFinal || !Nome) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Responsável e nome do idoso são obrigatórios.',
      });
    }

    const [idosoResult] = await connection.query(
  `
  INSERT INTO idoso 
  (
    IdResponsavel,
    IdMobilidade,
    IdNivelAutonomia,
    Nome,
    DataNascimento,
    Sexo,
    CuidadosMedicos,
    DescricaoExtra,
    UsaMedicacao,
    MedicacaoDetalhes,
    PrecisaBanho,
    BanhoDetalhes,
    PrecisaAlimentacao,
    AlimentacaoDetalhes,
    PrecisaAcompanhamento,
    AcompanhamentoDetalhes
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `,
  [
    idResponsavelFinal,
    IdMobilidade || null,
    IdNivelAutonomia || null,
    Nome,
    DataNascimento || null,
    Sexo || null,
    CuidadosMedicos || null,
    DescricaoExtra || null,
    UsaMedicacao || null,
    MedicacaoDetalhes || null,
    PrecisaBanho || null,
    BanhoDetalhes || null,
    PrecisaAlimentacao || null,
    AlimentacaoDetalhes || null,
    PrecisaAcompanhamento || null,
    AcompanhamentoDetalhes || null,
  ]
);

    const idIdoso = idosoResult.insertId;

    if (ServicosDetalhados) {
      const medicacao = ServicosDetalhados.medicacao;
      const companhia = ServicosDetalhados.companhia;
      const banho = ServicosDetalhados.banho;
      const alimentacao = ServicosDetalhados.alimentacao;

      if (medicacao) {
        await connection.query(
          `
          INSERT INTO servico_idoso_detalhado
          (IdIdoso, TipoServico, Ativo, CuidadorResponsavel, Descricao, Horario)
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            idIdoso,
            'medicacao',
            medicacao.usaMedicacao === true ? 1 : 0,
            medicacao.cuidadorVaiAplicar === true ? 1 : 0,
            medicacao.nomeMedicamento || null,
            medicacao.horarioMedicamento || null,
          ]
        );
      }

      if (companhia) {
        await connection.query(
          `
          INSERT INTO servico_idoso_detalhado
          (IdIdoso, TipoServico, Ativo, CuidadorResponsavel, Descricao, Horario)
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            idIdoso,
            'companhia',
            companhia.precisaCompanhia === true ? 1 : 0,
            companhia.precisaCompanhia === true ? 1 : 0,
            companhia.precisaCompanhia === true
              ? 'Idoso precisa de companhia'
              : null,
            null,
          ]
        );
      }

      if (banho) {
        await connection.query(
          `
          INSERT INTO servico_idoso_detalhado
          (IdIdoso, TipoServico, Ativo, CuidadorResponsavel, Descricao, Horario)
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            idIdoso,
            'banho',
            banho.precisaBanho === true ? 1 : 0,
            banho.precisaAjudaBanho === true ? 1 : 0,
            banho.precisaAjudaBanho === true
              ? 'Precisa de ajuda com o banho'
              : banho.precisaBanho === true
                ? 'Precisa de banho'
                : null,
            null,
          ]
        );
      }

      if (alimentacao) {
        await connection.query(
          `
          INSERT INTO servico_idoso_detalhado
          (IdIdoso, TipoServico, Ativo, CuidadorResponsavel, Descricao, Horario)
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            idIdoso,
            'alimentacao',
            alimentacao.precisaAjudaAlimentacao === true ? 1 : 0,
            alimentacao.precisaAjudaAlimentacao === true ? 1 : 0,
            alimentacao.precisaAjudaAlimentacao === true
              ? 'Precisa de ajuda com alimentação'
              : null,
            null,
          ]
        );
      }
    }

    await connection.commit();

    return res.status(201).json({
      success: true,
      message: 'Idoso cadastrado com sucesso!',
      idosoId: idIdoso,
    });
  } catch (error) {
    await connection.rollback();

    console.error('Erro ao cadastrar idoso:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao cadastrar idoso.',
      error: error.message,
    });
  } finally {
    connection.release();
  }
});

router.get('/meus', authenticateToken, async (req, res) => {
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
      SELECT *
      FROM idoso
      WHERE IdResponsavel = ?
      ORDER BY IdIdoso DESC
      `,
      [idResponsavel]
    );

    const idosos = normalizarRows(resultado);

    return res.json({
      success: true,
      data: idosos,
    });
  } catch (error) {
    console.error('Erro ao buscar meus idosos:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar idosos.',
      error: error.message,
    });
  }
});

router.get('/responsavel/:idResponsavel', async (req, res) => {
  try {
    const { idResponsavel } = req.params;

    const resultado = await db.query(
      `
      SELECT *
      FROM idoso
      WHERE IdResponsavel = ?
      ORDER BY IdIdoso DESC
      `,
      [idResponsavel]
    );

    const idosos = normalizarRows(resultado);

    return res.json({
      success: true,
      data: idosos,
    });
  } catch (error) {
    console.error('Erro ao buscar idosos:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar idosos.',
      error: error.message,
    });
  }
});

router.get('/:idIdoso', async (req, res) => {
  try {
    const { idIdoso } = req.params;

    const resultadoIdoso = await db.query(
      `
      SELECT *
      FROM idoso
      WHERE IdIdoso = ?
      LIMIT 1
      `,
      [idIdoso]
    );

    const idosoRows = normalizarRows(resultadoIdoso);

    if (idosoRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Idoso não encontrado.',
      });
    }

    const resultadoServicos = await db.query(
      `
      SELECT *
      FROM servico_idoso_detalhado
      WHERE IdIdoso = ?
      `,
      [idIdoso]
    );

    const servicos = normalizarRows(resultadoServicos);

    return res.json({
      success: true,
      data: {
        ...idosoRows[0],
        servicosDetalhados: servicos,
      },
    });
  } catch (error) {
    console.error('Erro ao buscar idoso:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao buscar idoso.',
      error: error.message,
    });
  }
});

router.put('/:idIdoso', authenticateToken, async (req, res) => {
  try {
    const { idIdoso } = req.params;
    const idResponsavel = getResponsavelId(req);

    const {
      IdMobilidade,
      IdNivelAutonomia,
      Nome,
      DataNascimento,
      Sexo,
      CuidadosMedicos,
      DescricaoExtra,
      UsaMedicacao,
      MedicacaoDetalhes,
      PrecisaBanho,
      BanhoDetalhes,
      PrecisaAlimentacao,
      AlimentacaoDetalhes,
      PrecisaAcompanhamento,
      AcompanhamentoDetalhes,
    } = req.body;

    const existe = await db.query(
      `SELECT IdIdoso FROM idoso WHERE IdIdoso = ? AND IdResponsavel = ? LIMIT 1`,
      [idIdoso, idResponsavel]
    );

    if (!existe || existe.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Idoso não encontrado ou sem permissão para editar.',
      });
    }

    await db.query(
      `
      UPDATE idoso
      SET
        IdMobilidade = ?,
        IdNivelAutonomia = ?,
        Nome = ?,
        DataNascimento = ?,
        Sexo = ?,
        CuidadosMedicos = ?,
        DescricaoExtra = ?,
        UsaMedicacao = ?,
        MedicacaoDetalhes = ?,
        PrecisaBanho = ?,
        BanhoDetalhes = ?,
        PrecisaAlimentacao = ?,
        AlimentacaoDetalhes = ?,
        PrecisaAcompanhamento = ?,
        AcompanhamentoDetalhes = ?
      WHERE IdIdoso = ? AND IdResponsavel = ?
      `,
      [
        IdMobilidade || null,
        IdNivelAutonomia || null,
        Nome,
        DataNascimento || null,
        Sexo || null,
        CuidadosMedicos || null,
        DescricaoExtra || null,
        UsaMedicacao || null,
        MedicacaoDetalhes || null,
        PrecisaBanho || null,
        BanhoDetalhes || null,
        PrecisaAlimentacao || null,
        AlimentacaoDetalhes || null,
        PrecisaAcompanhamento || null,
        AcompanhamentoDetalhes || null,
        idIdoso,
        idResponsavel,
      ]
    );

    return res.json({
      success: true,
      message: 'Dados do idoso atualizados com sucesso.',
    });
  } catch (error) {
    console.error('Erro ao atualizar idoso:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao atualizar idoso.',
      error: error.message,
    });
  }
});

router.delete('/:idIdoso', authenticateToken, async (req, res) => {
  try {
    const { idIdoso } = req.params;
    const idResponsavel = getResponsavelId(req);

    const existe = await db.query(
      `SELECT IdIdoso FROM idoso WHERE IdIdoso = ? AND IdResponsavel = ? LIMIT 1`,
      [idIdoso, idResponsavel]
    );

    if (!existe || existe.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Idoso não encontrado ou sem permissão para excluir.',
      });
    }

    await db.query(
      `DELETE FROM idoso WHERE IdIdoso = ? AND IdResponsavel = ?`,
      [idIdoso, idResponsavel]
    );

    return res.json({
      success: true,
      message: 'Idoso excluído com sucesso.',
    });
  } catch (error) {
    console.error('Erro ao excluir idoso:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao excluir idoso.',
      error: error.message,
    });
  }
});

module.exports = router;