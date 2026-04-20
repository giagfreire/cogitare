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

    const preference = new Preference(client);

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

    // Só adiciona notification_url se você tiver uma URL pública real
    if (
      process.env.MP_WEBHOOK_URL &&
      process.env.MP_WEBHOOK_URL.trim() !== ''
    ) {
      body.notification_url = process.env.MP_WEBHOOK_URL.trim();
    }

    const preferenceInstance = new Preference(client);
    const result = await preferenceInstance.create({ body });

    return res.status(200).json({
      success: true,
      message: 'Preferência criada com sucesso',
      data: {
        id: result.id,
        init_point: result.init_point,
        sandbox_init_point: result.sandbox_init_point,
      },
    });
  } catch (error) {
    console.error('ERRO MERCADO PAGO:', error);

    return res.status(500).json({
      success: false,
      message: 'Erro ao criar pagamento',
      error:
        process.env.NODE_ENV === 'development'
          ? error.message
          : undefined,
    });
  }
});

// =========================
// WEBHOOK
// =========================
router.post('/webhook', async (req, res) => {
  try {
    console.log('WEBHOOK RECEBIDO QUERY:', req.query);
    console.log('WEBHOOK RECEBIDO BODY:', req.body);

    const topic = req.query.type || req.body?.type;
    const paymentId = req.query['data.id'] || req.body?.data?.id;

    // Mercado Pago pode mandar outros eventos também
    if (topic !== 'payment' || !paymentId) {
      return res.sendStatus(200);
    }

    const paymentInstance = new Payment(client);
    const paymentData = await paymentInstance.get({ id: paymentId });

    console.log('DADOS PAGAMENTO MP:', paymentData);

    const status = paymentData.status;
    const externalReference = paymentData.external_reference;
    const transactionAmount = paymentData.transaction_amount || 0;

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

    // Só ativa plano se o pagamento foi aprovado
    if (status === 'approved') {
      // Verifica se o plano existe
      const [planos] = await db.query(
        'SELECT * FROM plano WHERE IdPlano = ? LIMIT 1',
        [idPlano]
      );

      if (!planos || planos.length === 0) {
        console.log('Plano não encontrado:', idPlano);
        return res.sendStatus(200);
      }

      // Verifica se já existe assinatura do cuidador
      const [assinaturas] = await db.query(
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
        // Atualiza assinatura existente
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
          `✅ Assinatura atualizada para cuidador ${idCuidador}, plano ${idPlano}`
        );
      } else {
        // Cria nova assinatura
        await db.query(
          `
          INSERT INTO assinaturacuidador
          (IdCuidador, IdPlano, Status, DataInicio, DataFim, ContatosUsados)
          VALUES (?, ?, 'Ativa', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 0)
          `,
          [idCuidador, idPlano]
        );

        console.log(
          `✅ Nova assinatura criada para cuidador ${idCuidador}, plano ${idPlano}`
        );
      }

      // Histórico opcional, só se existir tabela pagamento
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
            String(paymentId),
            paymentData.order?.id ? String(paymentData.order.id) : null,
            status,
            Number(transactionAmount),
          ]
        );

        console.log('✅ Histórico de pagamento salvo');
      } catch (e) {
        console.log(
          'ℹ️ Tabela pagamento não encontrada ou insert falhou, seguindo normalmente.'
        );
      }
    } else {
      console.log(`Pagamento ainda não aprovado. Status: ${status}`);
    }

    return res.sendStatus(200);
  } catch (err) {
    console.error('ERRO WEBHOOK:', err);
    return res.sendStatus(500);
  }
});

module.exports = router;