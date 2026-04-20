const express = require('express');
const router = express.Router();
const { MercadoPagoConfig, Preference, Payment } = require('mercadopago');

const client = new MercadoPagoConfig({
  accessToken: process.env.MP_ACCESS_TOKEN,
});

/// 🔥 CRIAR PAGAMENTO
router.post('/criar-preferencia', async (req, res) => {
  try {
    const { idCuidador, idPlano, titulo, preco } = req.body;

    if (!idCuidador || !idPlano || !titulo || !preco) {
      return res.status(400).json({
        success: false,
        message: 'Dados obrigatórios faltando',
      });
    }

    const preference = new Preference(client);

   const result = await preference.create({
  body: {
    items: [
      {
        title: titulo,
        quantity: 1,
        unit_price: Number(preco),
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
    notification_url: 'https://SEU_LINK_PUBLICO/webhook/mercadopago',
  },
})
    res.json({
      success: true,
      data: {
        init_point: result.init_point,
      },
    });
  } catch (error) {
    console.error('ERRO MERCADO PAGO:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar pagamento',
    });
  }
});

/// 🔥 WEBHOOK (CONFIRMA PAGAMENTO)
router.post('/webhook', async (req, res) => {
  try {
    console.log('WEBHOOK RECEBIDO:', req.body);

    const paymentId = req.body?.data?.id;

    if (!paymentId) return res.sendStatus(200);

    const payment = new Payment(client);
    const data = await payment.get({ id: paymentId });

    console.log('STATUS:', data.status);

    if (data.status === 'approved') {
      const info = JSON.parse(data.external_reference || '{}');

      const idCuidador = info.idCuidador;
      const idPlano = info.idPlano;

      console.log('PAGAMENTO APROVADO:', idCuidador, idPlano);

      // 👉 AQUI DEPOIS vamos atualizar o banco (plano ativo)
    }

    res.sendStatus(200);
  } catch (err) {
    console.error('ERRO WEBHOOK:', err);
    res.sendStatus(500);
  }
});

module.exports = router;