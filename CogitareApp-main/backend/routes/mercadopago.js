const express = require('express');
const router = express.Router();
const { MercadoPagoConfig, Preference, Payment } = require('mercadopago');
const db = require('../config/database');

const client = new MercadoPagoConfig({
  accessToken: process.env.MP_ACCESS_TOKEN,
});

// =========================
// CRIAR PREFERÊNCIA
// =========================
router.post('/criar-preferencia', async (req, res) => {
  try {
    const { idCuidador, idPlano, titulo, preco } = req.body;

    if (!idCuidador || !idPlano || !titulo || !preco) {
      return res.status(400).json({
        success: false,
        message: 'Dados obrigatórios faltando',
      });
    }

    const precoNumero = Number(preco);

    if (isNaN(precoNumero) || precoNumero <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Preço inválido',
      });
    }

    const body = {
      items: [
        {
          id: String(idPlano),
          title: titulo,
          quantity: 1,
          unit_price: precoNumero,
          currency_id: 'BRL',
        },
      ],
      back_urls: {
        success: 'https://www.google.com',
        failure: 'https://www.google.com',
        pending: 'https://www.google.com',
      },
      external_reference: JSON.stringify({
        idCuidador,
        idPlano,
      }),
    };

    if (process.env.MP_WEBHOOK_URL && process.env.MP_WEBHOOK_URL.trim() !== '') {
      body.notification_url = process.env.MP_WEBHOOK_URL.trim();
    }

    const preferenceInstance = new Preference(client);
    const result = await preferenceInstance.create({ body });

    // Salva histórico como pendente
    try {
      await db.query(
        `
        INSERT INTO pagamento
        (IdCuidador, IdPlano, PaymentId, PreferenceId, Status, Valor)
        VALUES (?, ?, ?, ?, ?, ?)
        `,
        [
          idCuidador,
          idPlano,
          null,
          result.id ? String(result.id) : null,
          'pending',
          precoNumero,
        ]
      );
    } catch (e) {
      console.log('ℹ️ Não foi possível salvar pagamento pendente:', e.message);
    }

    return res.status(200).json({
      success: true,
      message: 'Preferência criada com sucesso',
      data: {
        id: result.id,
        init_point: result.init_point,
        sandbox_init_point: result.sandbox_init_point,
        status: 'pending',
      },
    });
  } catch (error) {
    console.error('ERRO MERCADO PAGO:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao criar pagamento',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

// =========================
// WEBHOOK MERCADO PAGO
// =========================
router.post('/webhook', async (req, res) => {
  try {
    console.log('WEBHOOK RECEBIDO QUERY:', req.query);
    console.log('WEBHOOK RECEBIDO BODY:', req.body);

    const topic = req.query.type || req.body?.type;
    const paymentId = req.query['data.id'] || req.body?.data?.id;

    if (topic !== 'payment' || !paymentId) {
      return res.sendStatus(200);
    }

    const paymentInstance = new Payment(client);
    const paymentData = await paymentInstance.get({ id: paymentId });

    console.log('DADOS PAGAMENTO MP:', paymentData);

    const status = paymentData.status;
    const externalReference = paymentData.external_reference;
    const transactionAmount = Number(paymentData.transaction_amount || 0);
    const preferenceId = paymentData.preference_id
      ? String(paymentData.preference_id)
      : null;

    let idCuidador = null;
    let idPlano = null;

    try {
      const info = JSON.parse(externalReference || '{}');
      idCuidador = info.idCuidador;
      idPlano = info.idPlano;
    } catch (e) {
      console.error('ERRO AO LER external_reference:', e);
    }

    if (!idCuidador || !idPlano) {
      console.log('Webhook sem idCuidador/idPlano válidos.');
      return res.sendStatus(200);
    }

    // Atualiza/salva histórico do pagamento
    try {
      const pagamentos = await db.query(
        `
        SELECT *
        FROM pagamento
        WHERE PreferenceId = ?
        ORDER BY IdPagamento DESC
        LIMIT 1
        `,
        [preferenceId]
      );

      if (pagamentos && pagamentos.length > 0) {
        await db.query(
          `
          UPDATE pagamento
          SET
            PaymentId = ?,
            Status = ?,
            Valor = ?
          WHERE IdPagamento = ?
          `,
          [
            String(paymentId),
            status,
            transactionAmount,
            pagamentos[0].IdPagamento,
          ]
        );
      } else {
        await db.query(
          `
          INSERT INTO pagamento
          (IdCuidador, IdPlano, PaymentId, PreferenceId, Status, Valor)
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            idCuidador,
            idPlano,
            String(paymentId),
            preferenceId,
            status,
            transactionAmount,
          ]
        );
      }

      console.log('✅ Histórico de pagamento atualizado:', status);
    } catch (e) {
      console.log('ℹ️ Erro ao salvar histórico de pagamento:', e.message);
    }

    // Só ativa plano se pagamento aprovado
    if (status === 'approved') {
      const planos = await db.query(
        'SELECT * FROM plano WHERE IdPlano = ? LIMIT 1',
        [idPlano]
      );

      if (!planos || planos.length === 0) {
        console.log('Plano não encontrado:', idPlano);
        return res.sendStatus(200);
      }

      const assinaturas = await db.query(
        `
        SELECT *
        FROM assinaturacuidador
        WHERE IdCuidador = ?
        ORDER BY IdAssinatura DESC
        LIMIT 1
        `,
        [idCuidador]
      );

      if (assinaturas && assinaturas.length > 0) {
        await db.query(
          `
          UPDATE assinaturacuidador
          SET
            IdPlano = ?,
            Status = 'Ativa',
            DataInicio = NOW(),
            DataFim = DATE_ADD(NOW(), INTERVAL 30 DAY),
            ContatosUsados = 0
          WHERE IdAssinatura = ?
          `,
          [idPlano, assinaturas[0].IdAssinatura]
        );

        console.log(
          `✅ Assinatura atualizada: cuidador ${idCuidador}, plano ${idPlano}`
        );
      } else {
        await db.query(
          `
          INSERT INTO assinaturacuidador
          (IdCuidador, IdPlano, Status, DataInicio, DataFim, ContatosUsados)
          VALUES (?, ?, 'Ativa', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 0)
          `,
          [idCuidador, idPlano]
        );

        console.log(
          `✅ Nova assinatura criada: cuidador ${idCuidador}, plano ${idPlano}`
        );
      }
    } else {
      console.log(`Pagamento recebido, mas ainda não aprovado. Status: ${status}`);
    }

    return res.sendStatus(200);
  } catch (err) {
    console.error('ERRO WEBHOOK:', err);
    return res.sendStatus(500);
  }
});

// =========================
// CONSULTAR ÚLTIMO PAGAMENTO DO CUIDADOR
// =========================
router.get('/status-pagamento/:idCuidador', async (req, res) => {
  try {
    const { idCuidador } = req.params;

    const pagamentos = await db.query(
      `
      SELECT *
      FROM pagamento
      WHERE IdCuidador = ?
      ORDER BY IdPagamento DESC
      LIMIT 1
      `,
      [idCuidador]
    );

    if (!pagamentos || pagamentos.length === 0) {
      return res.status(200).json({
        success: true,
        data: null,
        message: 'Nenhum pagamento encontrado',
      });
    }

    return res.status(200).json({
      success: true,
      data: pagamentos[0],
    });
  } catch (error) {
    console.error('ERRO STATUS PAGAMENTO:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao consultar status do pagamento',
      error: error.message,
    });
  }
});

module.exports = router;